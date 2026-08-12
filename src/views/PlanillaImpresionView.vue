<template>
  <div>
    <div class="d-flex justify-content-between align-items-center mb-3 no-print">
      <h4 class="mb-0"><i class="bi bi-table me-2"></i>Imprimir Planilla Completa</h4>
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
          <div class="col-md-7 d-flex align-items-end justify-content-end">
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
        <div>CNSS {{ (planillaActual.empresa && planillaActual.empresa.cnss) || '' }}</div>
        <div>NIT {{ (planillaActual.empresa && planillaActual.empresa.nit) || '' }}</div>
        <div>Zona: {{ (planillaActual.empresa && planillaActual.empresa.zona) || '' }}</div>
        <div>Calle: {{ (planillaActual.empresa && planillaActual.empresa.calle) || '' }}</div>
        <div>{{ (planillaActual.empresa && planillaActual.empresa.ciudad) || '' }}</div>
        <div>Telf: {{ (planillaActual.empresa && planillaActual.empresa.telefono) || '' }}</div>
      </div>

      <div class="pp-titulo">{{ titulo }}</div>

      <div class="pp-tabla-wrap">
        <table class="planilla-tabla">
          <colgroup>
            <col style="width: 1.6%" />
            <col style="width: 3%" />
            <col style="width: 4.5%" />
            <col style="width: 2%" />
            <col style="width: 3.5%" />
            <col style="width: 4.5%" />
            <col style="width: 6%" />
            <col style="width: 6%" />
            <col style="width: 7.5%" />
            <col style="width: 4%" />
            <col style="width: 4%" />
            <col style="width: 1.5%" />
            <col style="width: 2.5%" />
            <col style="width: 8%" />
            <col style="width: 4%" />
            <col style="width: 3%" />
            <col style="width: 4.5%" />
            <col style="width: 4.5%" />
            <col style="width: 4.5%" />
            <col style="width: 4.5%" />
            <col style="width: 4.5%" />
            <col style="width: 4.5%" />
            <col style="width: 4.5%" />
            <col style="width: 4.5%" />
            <col style="width: 4.5%" />
            <col style="width: 8%" />
          </colgroup>
          <thead>
            <tr>
              <th>Nº</th>
              <th>Tipo Doc.</th>
              <th>Nº Documento</th>
              <th>Ext.</th>
              <th>AFP</th>
              <th>NUA/CUA</th>
              <th>Apellido Paterno</th>
              <th>Apellido Materno</th>
              <th>Nombre 1 / Otros</th>
              <th>País</th>
              <th>F. Nacimiento</th>
              <th>Sexo</th>
              <th>Jubilado</th>
              <th>Cargo</th>
              <th>F. Ingreso</th>
              <th>Horas</th>
              <th>Haber Básico</th>
              <th>Bono Antig.</th>
              <th>Otros Bonos</th>
              <th>Total Ganado</th>
              <th>Aportes AFP</th>
              <th>Otros Desc.</th>
              <th>Total Desc.</th>
              <th>Líquido</th>
              <th>Firma</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="f in filas" :key="f.item">
              <td>{{ f.item }}</td>
              <td>{{ f.tipoDoc }}</td>
              <td>{{ f.nroDoc }}</td>
              <td>{{ f.ext }}</td>
              <td class="izq">{{ f.afp }}</td>
              <td>{{ f.nua }}</td>
              <td class="izq">{{ f.apPat }}</td>
              <td class="izq">{{ f.apMat }}</td>
              <td class="izq">{{ f.nombres }}</td>
              <td class="izq">{{ f.pais }}</td>
              <td>{{ f.fnac }}</td>
              <td>{{ f.sexo }}</td>
              <td>{{ f.jubilado }}</td>
              <td class="izq">{{ f.cargo }}</td>
              <td>{{ f.fing }}</td>
              <td>{{ f.horas }}</td>
              <td>{{ f.haber }}</td>
              <td>{{ f.bono }}</td>
              <td>{{ f.otros }}</td>
              <td>{{ f.totalGan }}</td>
              <td>{{ f.aportes }}</td>
              <td>{{ f.otrosDesct }}</td>
              <td>{{ f.totalDesct }}</td>
              <td>{{ f.liquido }}</td>
              <td class="firma"></td>
            </tr>
          </tbody>
          <tfoot>
            <tr class="pp-totales">
              <td colspan="15" class="izq fw-bold">TOTALES</td>
              <td class="fw-bold">{{ totales.horas }}</td>
              <td class="fw-bold">{{ totales.haber }}</td>
              <td class="fw-bold">{{ totales.bono }}</td>
              <td class="fw-bold">{{ totales.otros }}</td>
              <td class="fw-bold">{{ totales.totalGan }}</td>
              <td class="fw-bold">{{ totales.aportes }}</td>
              <td class="fw-bold">{{ totales.otrosDesct }}</td>
              <td class="fw-bold">{{ totales.totalDesct }}</td>
              <td class="fw-bold">{{ totales.liquido }}</td>
              <td class="firma"></td>
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
const alerta = ref(null)

function mostrarAlerta(texto, tipo) {
  alerta.value = { texto, tipo }
  setTimeout(() => (alerta.value = null), 5000)
}

function fmtNum(v) {
  if (v === null || v === undefined) return '0.00'
  return Number(v).toFixed(2)
}

function fmtFecha(s) {
  if (!s) return ''
  const [y, m, d] = String(s).split('-')
  if (!y || !m || !d) return s
  return `${d}/${m}/${y}`
}

const titulo = computed(() => {
  if (!planillaActual.value) return ''
  const mes = meses[((planillaActual.value.periodoMes || 1) - 1) % 12]
  return `PLANILLA DE HABERES MES DE ${mes.toUpperCase()} ${planillaActual.value.periodoAnio}`
})

const filas = computed(() =>
  detalles.value.map((d) => {
    const per = (d.empleado && d.empleado.persona) || {}
    const emp = d.empleado || {}
    return {
      item: d.item,
      tipoDoc: per.tipoDocumento,
      nroDoc: per.nroDocumento,
      ext: emp.origen,
      afp: emp.afp,
      nua: emp.nuaCua,
      apPat: per.apellidoPaterno,
      apMat: per.apellidoMaterno,
      nombres: per.nombres,
      pais: per.paisNacionalidad,
      fnac: fmtFecha(per.fechaNacimiento),
      sexo: per.sexo,
      jubilado: emp.jubilado ? 'Sí' : 'No',
      cargo: emp.cargo,
      fing: fmtFecha(emp.fechaIngreso),
      horas: fmtNum(d.horasTrabajadas),
      haber: fmtNum(d.haberBasico),
      bono: fmtNum(d.bonoAntigMonto),
      otros: fmtNum(d.salarioDominical),
      totalGan: fmtNum(d.totalGanado),
      aportes: fmtNum(d.totalAportes),
      otrosDesct: fmtNum(d.descuentosVarios),
      totalDesct: fmtNum(d.totalDescuentos),
      liquido: fmtNum(d.liquidoPagable)
    }
  })
)

const totales = computed(() => {
  const t = { horas: 0, haber: 0, bono: 0, otros: 0, totalGan: 0, aportes: 0, otrosDesct: 0, totalDesct: 0, liquido: 0 }
  detalles.value.forEach((d) => {
    t.horas += Number(d.horasTrabajadas) || 0
    t.haber += Number(d.haberBasico) || 0
    t.bono += Number(d.bonoAntigMonto) || 0
    t.otros += Number(d.salarioDominical) || 0
    t.totalGan += Number(d.totalGanado) || 0
    t.aportes += Number(d.totalAportes) || 0
    t.otrosDesct += Number(d.descuentosVarios) || 0
    t.totalDesct += Number(d.totalDescuentos) || 0
    t.liquido += Number(d.liquidoPagable) || 0
  })
  Object.keys(t).forEach((k) => { t[k] = fmtNum(t[k]) })
  return t
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
  planillaActual.value = null
  if (!planillaId.value) return
  try {
    const [p, d] = await Promise.all([
      api.get(`/planillas/${planillaId.value}`),
      api.get(`/planillas/${planillaId.value}/detalles`)
    ])
    planillaActual.value = p.data
    detalles.value = d.data
  } catch (e) {
    mostrarAlerta(mensajeError(e), 'alert-danger')
  }
}

function imprimir() {
  if (detalles.value.length === 0) {
    mostrarAlerta('La planilla no tiene datos para imprimir', 'alert-warning')
    return
  }
  window.print()
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
}

.planilla-tabla .izq {
  text-align: left;
}

.planilla-tabla td.firma {
  height: 18px;
}

.planilla-tabla tbody tr:nth-child(even) {
  background: #f5f7fa;
}
</style>
