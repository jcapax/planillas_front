<template>
  <div>
    <div class="d-flex justify-content-between align-items-center mb-3">
      <h4 class="mb-0"><i class="bi bi-clipboard-data me-2"></i>Copiar Descuentos entre Planillas</h4>
    </div>

    <div v-if="alerta" class="alert" :class="alerta.tipo">{{ alerta.texto }}</div>

    <div class="card shadow-sm border-0 mb-3">
      <div class="card-header">Origen, descuento y destino</div>
      <div class="card-body">
        <div class="row g-3 align-items-end">
          <div class="col-md-4">
            <label class="form-label">Planilla origen *</label>
            <select v-model="origenId" class="form-select" @change="cargarMatrices">
              <option :value="null" disabled>-- Seleccionar planilla --</option>
              <option v-for="p in planillas" :key="p.id" :value="p.id">{{ p.nombre }}</option>
            </select>
          </div>
          <div class="col-md-4">
            <label class="form-label">Descuento a copiar *</label>
            <select v-model="conceptoId" class="form-select">
              <option :value="null" disabled>-- Seleccionar descuento --</option>
              <option v-for="c in conceptos" :key="c.id" :value="c.id">
                {{ c.nombre }} ({{ c.tipo }})
              </option>
            </select>
          </div>
          <div class="col-md-4">
            <label class="form-label">Planilla destino *</label>
            <select v-model="destinoId" class="form-select" @change="cargarMatrices">
              <option :value="null" disabled>-- Seleccionar planilla --</option>
              <option v-for="p in planillas" :key="p.id" :value="p.id">{{ p.nombre }}</option>
            </select>
          </div>
        </div>
        <div class="d-flex justify-content-between align-items-center mt-3">
          <p class="text-muted small mb-0">            
          </p>
          <button class="btn btn-primary ms-3" :disabled="!puedeCopiar || copiando" @click="copiar">
            <span v-if="copiando" class="spinner-border spinner-border-sm me-1"></span>
            <i v-else class="bi bi-arrow-right-circle me-1"></i>Copiar al destino
          </button>
        </div>
        <p v-if="origenId && destinoId && origenId === destinoId" class="text-danger small mt-2 mb-0">
          La planilla origen y la destino son la misma. Elija un destino distinto.
        </p>
        <p v-if="origenId && origenFilas.length === 0 && !cargando" class="text-warning small mt-2 mb-0">
          La planilla origen no tiene detalles generados. Genérela desde "Gestión de Planillas".
        </p>
        <p v-if="destinoId && destinoFilas.length === 0 && !cargando" class="text-warning small mt-2 mb-0">
          La planilla destino no tiene detalles generados. Genérela antes de copiar.
        </p>
      </div>
    </div>

    <div v-if="filasVista.length > 0" class="card shadow-sm border-0">
      <div class="card-header d-flex justify-content-between align-items-center">
        <span>Vista previa</span>
        <span class="text-muted small">
          {{ resumen.copiar }} a copiar · {{ resumen.quitar }} se quitan ·
          {{ resumen.igual }} sin cambio · total {{ fmtNumero(resumen.totalOrigen) }} Bs
        </span>
      </div>
      <div class="card-body">
        <div class="table-responsive">
          <table class="table table-sm table-hover align-middle mb-0">
            <thead class="table-light">
              <tr>
                <th>Empleado</th>
                <th>Documento</th>
                <th class="text-end">Monto origen (Bs)</th>
                <th class="text-end">Monto actual destino (Bs)</th>
                <th class="text-center">Acción</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="f in filasVista" :key="f.empleadoId">
                <td>{{ f.nombre }}</td>
                <td>{{ f.documento }}</td>
                <td class="text-end">{{ fmtNumero(f.origen) }}</td>
                <td class="text-end">{{ fmtNumero(f.destino) }}</td>
                <td class="text-center">
                  <span class="badge" :class="badgeAccion(f.accion)">{{ textoAccion(f.accion) }}</span>
                </td>
              </tr>
            </tbody>
            <tfoot class="table-light">
              <tr>
                <td colspan="2" class="fw-bold">Total</td>
                <td class="text-end fw-bold">{{ fmtNumero(resumen.totalOrigen) }}</td>
                <td class="text-end fw-bold">{{ fmtNumero(resumen.totalDestino) }}</td>
                <td></td>
              </tr>
            </tfoot>
          </table>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed, onMounted, ref } from 'vue'
import api, { mensajeError } from '../services/api'

const planillas = ref([])
const conceptos = ref([])
const origenId = ref(null)
const destinoId = ref(null)
const conceptoId = ref(null)
const origenFilas = ref([])
const destinoFilas = ref([])
const cargando = ref(false)
const copiando = ref(false)
const alerta = ref(null)

const claveConcepto = computed(() => (conceptoId.value != null ? String(conceptoId.value) : null))

function mostrarAlerta(texto, tipo) {
  alerta.value = { texto, tipo }
  setTimeout(() => (alerta.value = null), 5000)
}

function fmtNumero(v) {
  if (v === null || v === undefined) return '0,00'
  return Number(v).toLocaleString('es-BO', { minimumFractionDigits: 2, maximumFractionDigits: 2 })
}

function badgeAccion(accion) {
  return { copiar: 'bg-success', quitar: 'bg-danger', igual: 'bg-secondary' }[accion] || 'bg-secondary'
}

function textoAccion(accion) {
  return { copiar: 'Copiar', quitar: 'Quitar', igual: 'Sin cambio' }[accion] || accion
}

function montoDe(fila) {
  if (!claveConcepto.value || !fila.montos) return 0
  return Number(fila.montos[claveConcepto.value]) || 0
}

const filasVista = computed(() => {
  if (!claveConcepto.value) return []
  const porEmpleado = new Map()
  for (const f of destinoFilas.value) {
    if (f.empleadoId == null) continue
    porEmpleado.set(f.empleadoId, {
      empleadoId: f.empleadoId,
      nombre: f.nombre,
      documento: f.documento,
      destino: montoDe(f),
      origen: 0
    })
  }
  for (const f of origenFilas.value) {
    if (f.empleadoId == null) continue
    const fila = porEmpleado.get(f.empleadoId) || {
      empleadoId: f.empleadoId,
      nombre: f.nombre,
      documento: f.documento,
      destino: 0,
      origen: 0
    }
    fila.nombre = fila.nombre || f.nombre
    fila.documento = fila.documento || f.documento
    fila.origen = montoDe(f)
    porEmpleado.set(f.empleadoId, fila)
  }
  return [...porEmpleado.values()]
    .filter((f) => f.origen > 0 || f.destino > 0)
    .map((f) => ({
      ...f,
      accion: f.origen > 0 ? (f.origen === f.destino ? 'igual' : 'copiar') : 'quitar'
    }))
    .sort((a, b) => (b.origen + b.destino) - (a.origen + a.destino) || String(a.nombre).localeCompare(String(b.nombre)))
})

const resumen = computed(() => {
  const r = { copiar: 0, quitar: 0, igual: 0, totalOrigen: 0, totalDestino: 0 }
  for (const f of filasVista.value) {
    r[f.accion]++
    r.totalOrigen += f.origen
    r.totalDestino += f.destino
  }
  return r
})

const puedeCopiar = computed(() =>
  origenId.value != null &&
  destinoId.value != null &&
  conceptoId.value != null &&
  origenId.value !== destinoId.value &&
  origenFilas.value.length > 0 &&
  destinoFilas.value.length > 0
)

async function cargarPlanillas() {
  try {
    const { data } = await api.get('/planillas')
    planillas.value = data
  } catch (e) {
    mostrarAlerta(mensajeError(e), 'alert-danger')
  }
}

async function cargarConceptos() {
  try {
    const { data } = await api.get('/conceptos')
    conceptos.value = (data || []).filter((c) =>
      c.activo !== false &&
      (c.tipo === 'DESCUENTO' || c.tipo === 'APORTE') &&
      c.tipoDescuento !== 'FIJO'
    )
  } catch (e) {
    mostrarAlerta(mensajeError(e), 'alert-danger')
  }
}

function normalizarFilas(filas) {
  return (filas || []).map((f) => {
    const montos = {}
    for (const [k, v] of Object.entries(f.montos || {})) montos[k] = Number(v) || 0
    return { ...f, montos }
  })
}

async function cargarMatriz(planillaId) {
  const { data } = await api.get(`/planillas/${planillaId}/descuentos-matriz`)
  return normalizarFilas(data.filas)
}

async function cargarMatrices() {
  cargando.value = true
  try {
    const [o, d] = await Promise.all([
      origenId.value ? cargarMatriz(origenId.value) : Promise.resolve([]),
      destinoId.value ? cargarMatriz(destinoId.value) : Promise.resolve([])
      ])
      origenFilas.value = o
      destinoFilas.value = d
  } catch (e) {
    mostrarAlerta(mensajeError(e), 'alert-danger')
  } finally {
    cargando.value = false
  }
}

async function copiar() {
  if (!puedeCopiar.value || copiando.value) return
  copiando.value = true
  try {
    const { data } = await api.post('/planillas/copiar-descuentos', {
      origenId: origenId.value,
      destinoId: destinoId.value,
      conceptoId: conceptoId.value
    })
    mostrarAlerta(
      `${data.mensaje}. Aplicados: ${data.aplicados}, quitados: ${data.quitados}.`,
      'alert-success'
    )
    await cargarMatriz(destinoId.value).then((f) => (destinoFilas.value = f))
  } catch (e) {
    mostrarAlerta(mensajeError(e), 'alert-danger')
  } finally {
    copiando.value = false
  }
}

onMounted(() => {
  cargarPlanillas()
  cargarConceptos()
})
</script>
