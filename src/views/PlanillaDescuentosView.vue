<template>
  <div>
    <div class="d-flex justify-content-between align-items-center mb-3 no-print">
      <h4 class="mb-0"><i class="bi bi-cash-stack me-2"></i>Planilla de Descuentos</h4>
    </div>

    <div v-if="alerta" class="alert no-print" :class="alerta.tipo">{{ alerta.texto }}</div>

    <div class="card shadow-sm border-0 mb-4 no-print">
      <div class="card-header">Selección de planilla</div>
      <div class="card-body">
        <div class="row g-3">
          <div class="col-md-5">
            <label class="form-label">Planilla</label>
            <select v-model="planillaId" class="form-select" @change="cargarPlanilla">
              <option :value="null" disabled>-- Seleccionar planilla --</option>
              <option v-for="p in planillas" :key="p.id" :value="p.id">
                {{ p.nombre }}
              </option>
            </select>
          </div>
          <div class="col-md-7 d-flex align-items-end justify-content-end gap-2">
            <button class="btn btn-success" :disabled="detalles.length === 0 || generandoPdf" @click="generarPdf">
              <span v-if="generandoPdf" class="spinner-border spinner-border-sm me-1"></span>
              <i v-else class="bi bi-file-earmark-pdf me-1"></i>Generar PDF
            </button>
            <button class="btn btn-primary" :disabled="detalles.length === 0" @click="imprimir">
              <i class="bi bi-printer me-1"></i>Imprimir
            </button>
          </div>
        </div>
        <p v-if="planillaId && detalles.length === 0" class="text-muted mb-0 mt-2">
          La planilla aún no tiene detalles generados. Genérela desde "Gestión de Planillas".
        </p>
      </div>
    </div>

    <div v-if="detalles.length > 0" class="planilla-print">
      <div class="pp-empresa">
        <div class="pp-l1">{{ (planillaActual.empresa && planillaActual.empresa.nombre) || '' }}</div>
        <div>SEGURO UNIVERSITARIO {{ (planillaActual.empresa && planillaActual.empresa.cnss) || '' }}</div>
        <div>NIT {{ (planillaActual.empresa && planillaActual.empresa.nit) || '' }}</div>
        <div>Zona: {{ (planillaActual.empresa && planillaActual.empresa.zona) || '' }}</div>
        <div>Calle: {{ (planillaActual.empresa && planillaActual.empresa.calle) || '' }}</div>
        <div>{{ (planillaActual.empresa && planillaActual.empresa.ciudad) || '' }}</div>
        <div>Telf: {{ (planillaActual.empresa && planillaActual.empresa.telefono) || '' }}</div>
      </div>

      <div class="pp-titulo">{{ titulo }}</div>

      <div class="pp-tabla-wrap">
        <table class="planilla-tabla">
          <thead>
            <tr>
              <th>Nº</th>
              <th>Nº Documento</th>
              <th>Nombre Completo</th>
              <th>Cargo</th>
              <th>Total Ganado</th>
              <th v-for="c in columnas" :key="c.id">{{ c.nombre }}</th>
              <th>Total Desc.</th>
              <th>Líquido</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="(f, index) in filas" :key="f.item">
              <td>{{ index + 1 }}</td>
              <td>{{ f.nroDoc }}</td>
              <td class="izq">{{ f.nombreCompleto }}</td>
              <td class="izq">{{ f.cargo }}</td>
              <td>{{ f.totalGan }}</td>
              <td v-for="c in columnas" :key="c.id">{{ f.montos[c.id] }}</td>
              <td>{{ f.totalDesct }}</td>
              <td>{{ f.liquido }}</td>
            </tr>
          </tbody>
          <tfoot>
            <tr class="pp-totales">
              <td colspan="4" class="izq fw-bold">TOTALES</td>
              <td class="fw-bold">{{ totales.totalGan }}</td>
              <td v-for="c in columnas" :key="c.id" class="fw-bold">{{ totales.montos[c.id] }}</td>
              <td class="fw-bold">{{ totales.totalDesct }}</td>
              <td class="fw-bold">{{ totales.liquido }}</td>
            </tr>
          </tfoot>
        </table>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed, onMounted, ref } from 'vue'
import api, { mensajeError } from '../services/api'
import '../assets/print-planilla.css'

const meses = ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
  'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre']

const planillas = ref([])
const planillaId = ref(null)
const planillaActual = ref(null)
const detalles = ref([])
const columnas = ref([])
const montosPorDetalle = ref({})
const alerta = ref(null)
const generandoPdf = ref(false)

function mostrarAlerta(texto, tipo) {
  alerta.value = { texto, tipo }
  setTimeout(() => (alerta.value = null), 5000)
}

const formatoNumero = new Intl.NumberFormat('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })
function fmtNum(v) {
  if (v === null || v === undefined) return '0.00'
  return formatoNumero.format(Number(v) || 0)
}

function nombreCompleto(per) {
  return [per.nombres, per.apellidoPaterno, per.apellidoMaterno, per.apellidoCasada]
    .filter((x) => x && String(x).trim())
    .join(' ')
    .trim()
}

const titulo = computed(() => {
  if (!planillaActual.value) return ''
  const mes = meses[((planillaActual.value.periodoMes || 1) - 1) % 12]
  return `PLANILLA DE DESCUENTOS MES DE ${mes.toUpperCase()} ${planillaActual.value.periodoAnio}`
})

const filas = computed(() =>
  [...detalles.value].sort((a, b) => (a.item ?? 0) - (b.item ?? 0)).map((d) => {
    const per = (d.empleado && d.empleado.persona) || {}
    const emp = d.empleado || {}
    const montos = montosPorDetalle.value[d.id] || {}
    const celdas = {}
    for (const c of columnas.value) {
      celdas[c.id] = fmtNum(montos[c.id])
    }
    return {
      item: d.item,
      nroDoc: per.nroDocumento,
      nombreCompleto: nombreCompleto(per),
      cargo: emp.cargo,
      totalGan: fmtNum(d.totalGanado),
      montos: celdas,
      totalDesct: fmtNum(d.totalDescuentos),
      liquido: fmtNum(d.liquidoPagable)
    }
  })
)

const totales = computed(() => {
  const t = { totalGan: 0, totalDesct: 0, liquido: 0, montos: {} }
  for (const c of columnas.value) t.montos[c.id] = 0
  detalles.value.forEach((d) => {
    t.totalGan += Number(d.totalGanado) || 0
    t.totalDesct += Number(d.totalDescuentos) || 0
    t.liquido += Number(d.liquidoPagable) || 0
    const montos = montosPorDetalle.value[d.id] || {}
    for (const c of columnas.value) {
      t.montos[c.id] += Number(montos[c.id]) || 0
    }
  })
  const salidos = { totalGan: fmtNum(t.totalGan), totalDesct: fmtNum(t.totalDesct), liquido: fmtNum(t.liquido), montos: {} }
  for (const c of columnas.value) salidos.montos[c.id] = fmtNum(t.montos[c.id])
  return salidos
})

async function cargarPlanillas() {
  try {
    const { data } = await api.get('/planillas')
    planillas.value = data
  } catch (e) {
    mostrarAlerta(mensajeError(e), 'alert-danger')
  }
}

async function cargarPlanilla() {
  detalles.value = []
  columnas.value = []
  montosPorDetalle.value = {}
  planillaActual.value = null
  if (!planillaId.value) return
  try {
    const [p, d, m] = await Promise.all([
      api.get(`/planillas/${planillaId.value}`),
      api.get(`/planillas/${planillaId.value}/detalles`),
      api.get(`/planillas/${planillaId.value}/descuentos-reporte`)
    ])
    planillaActual.value = p.data
    detalles.value = [...d.data].sort((a, b) => (a.item ?? 0) - (b.item ?? 0))
    columnas.value = m.data.conceptos || []
    const porDetalle = {}
    for (const fila of m.data.filas || []) {
      const montos = {}
      for (const [k, v] of Object.entries(fila.montos || {})) {
        montos[k] = Number(v) || 0
      }
      porDetalle[fila.detalleId] = montos
    }
    montosPorDetalle.value = porDetalle
  } catch (e) {
    mostrarAlerta(mensajeError(e), 'alert-danger')
  }
}

function imprimir() {
  window.print()
}

async function generarPdf() {
  if (detalles.value.length === 0 || generandoPdf.value) return
  generandoPdf.value = true
  try {
    const { data } = await api.get(`/planillas/${planillaId.value}/pdf-descuentos`, { responseType: 'blob' })
    const url = URL.createObjectURL(data)
    const enlace = document.createElement('a')
    enlace.href = url
    enlace.download = nombreArchivoPdf()
    document.body.appendChild(enlace)
    enlace.click()
    enlace.remove()
    URL.revokeObjectURL(url)
  } catch (e) {
    if (e.response && e.response.data instanceof Blob) {
      try {
        const texto = JSON.parse(await e.response.data.text())
        mostrarAlerta(texto.error || 'No se pudo generar el PDF', 'alert-danger')
      } catch {
        mostrarAlerta('No se pudo generar el PDF', 'alert-danger')
      }
    } else {
      mostrarAlerta(mensajeError(e), 'alert-danger')
    }
  } finally {
    generandoPdf.value = false
  }
}

function nombreArchivoPdf() {
  const p = planillaActual.value
  if (!p) return 'planilla_descuentos.pdf'
  const mes = meses[((p.periodoMes || 1) - 1) % 12].toLowerCase()
  return `planilla_descuentos_${mes}_${p.periodoAnio}.pdf`
}

onMounted(cargarPlanillas)
</script>

<style scoped>
.pp-empresa {
  font-size: 8px;
  line-height: 1.45;
  color: #000;
}

.pp-empresa .pp-l1 {
  font-weight: 700;
}

.pp-titulo {
  text-align: center;
  font-weight: 700;
  font-size: 11px;
  padding: 8px 0 6px;
  color: #000;
}

.pp-tabla-wrap {
  overflow-x: auto;
}

.planilla-tabla {
  width: 100%;
  border-collapse: collapse;
  font-size: 9px;
  color: #000;
}

.planilla-tabla th,
.planilla-tabla td {
  border: 1px solid #000;
  padding: 2px 3px;
  text-align: right;
  white-space: nowrap;
}

.planilla-tabla th {
  background: #e9eef5;
  text-align: center;
  font-weight: 700;
  white-space: normal;
  overflow-wrap: break-word;
}

.planilla-tabla .izq {
  text-align: left;
}

.planilla-tabla tbody tr:nth-child(even) {
  background: #f5f7fa;
}
</style>
