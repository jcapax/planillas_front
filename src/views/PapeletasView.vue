<template>
  <div>
    <div class="d-flex justify-content-between align-items-center mb-3 no-print">
      <h4 class="mb-0"><i class="bi bi-printer me-2"></i>Papeletas de Pago</h4>
    </div>

    <div v-if="alerta" class="alert no-print" :class="alerta.tipo">{{ alerta.texto }}</div>

    <div class="card shadow-sm border-0 mb-4 no-print">
      <div class="card-header">Selección de papeletas</div>
      <div class="card-body">
        <div class="row g-3">
          <div class="col-md-5">
            <label class="form-label">Planilla</label>
            <select v-model="planillaId" class="form-select" @change="cargarPapeletas">
              <option :value="null" disabled>-- Seleccionar planilla --</option>
              <option v-for="p in planillas" :key="p.id" :value="p.id">
                {{ p.nombre }}
              </option>
            </select>
          </div>
          <div class="col-md-7 d-flex align-items-end justify-content-end">
            <button
              class="btn btn-outline-secondary me-2"
              :disabled="!planillaId || papeletas.length === 0"
              @click="seleccionarTodos"
            >
              <i class="bi bi-check2-square me-1"></i>
              {{ todosSeleccionados ? 'Ninguno' : 'Todos' }}
            </button>
            <button class="btn btn-primary" :disabled="seleccionadas.length === 0" @click="imprimir">
              <i class="bi bi-printer me-1"></i>Imprimir ({{ seleccionadas.length }})
            </button>
          </div>
        </div>

        <div v-if="planillaId && papeletas.length > 0" class="mt-3">
          <label class="form-label">Empleados ({{ papeletas.length }})</label>
          <div class="papeleta-lista">
            <label
              v-for="p in papeletas"
              :key="p.detalleId"
              class="papeleta-opcion"
            >
              <input
                v-model="seleccion"
                type="checkbox"
                class="form-check-input me-2"
                :value="p.detalleId"
              />
              <span class="badge bg-secondary me-2">{{ p.item }}</span>
              <span class="fw-semibold">{{ p.empleado }}</span>
              <span class="text-muted ms-2">{{ p.documento }}</span>
              <span class="ms-auto fw-bold">{{ fmt(p.liquidoPagable) }}</span>
            </label>
          </div>
        </div>
        <p v-else-if="planillaId" class="text-muted mb-0 mt-2">
          La planilla aún no tiene detalles generados. Genérela desde "Gestión de Planillas".
        </p>
      </div>
    </div>

    <div v-if="seleccionadas.length > 0" class="mb-3 no-print">
      <h6 class="text-muted"><i class="bi bi-eye me-1"></i>Vista previa</h6>
    </div>

    <div class="papeletas-print">
      <div v-for="p in seleccionadas" :key="p.detalleId" class="papeleta">
        <div class="ph-cabecera">
          <div class="ph-empresa">{{ (planillaActual.empresa && planillaActual.empresa.nombre) || 'SIDS S.A.' }}</div>
          <div class="ph-titulo">LIQUIDACION DE SUELDOS</div>
          <div class="ph-fecha">{{ fmtFecha(planillaActual.fechaLiquidacion) }}</div>
        </div>

        <div class="ph-empleado">
          <span class="ph-item">ITEM Nº {{ p.item }}</span>
          <span class="ph-nombre">{{ p.empleado }}</span>
          <span class="ph-doc">{{ p.documento }}</span>
        </div>

        <div class="ph-resumen">
          <div class="ph-resumen-labels">
            <span>Nº</span>
            <span>TTAL GAN</span>
            <span>TTAL DESCTO</span>
            <span>LIQUIDO</span>
          </div>
          <div class="ph-resumen-valores">
            <span>{{ p.item }}</span>
            <span>{{ fmt(p.totalGanado) }}</span>
            <span>{{ fmt(p.totalDescuentos) }}</span>
            <span>{{ fmt(p.liquidoPagable) }}</span>
          </div>
        </div>

        <div class="ph-lineas">
          <div class="ph-linea ph-linea-cabecera">
            <span>DESCRIPCION</span>
            <span>HABERES</span>
            <span>DESCUENTOS</span>
          </div>
          <div v-for="l in p.lineas" :key="l.codigo" class="ph-linea">
            <span class="ph-desc">{{ l.nombre }}</span>
            <span>{{ l.tipo === 'HABER' ? fmt(l.monto) : '' }}</span>
            <span>{{ l.tipo !== 'HABER' ? fmt(l.monto) : '' }}</span>
          </div>
          <div class="ph-linea ph-total-hd">
            <span>TOTAL HABERES Y DESCUENTOS</span>
            <span>{{ fmt(p.totalGanado) }}</span>
            <span>{{ fmt(p.totalDescuentos) }}</span>
          </div>
          <div class="ph-linea ph-total-lq">
            <span>SALDO CREDITO / LIQUIDO PAGABLE</span>
            <span></span>
            <span>{{ fmt(p.liquidoPagable) }}</span>
          </div>
        </div>

        <div class="ph-nota">** revise su liquidación **</div>
        <div class="ph-firma">
          <span>RECIBI CONFORME</span>
          <span class="ph-firma-linea"></span>
          <span class="ph-firma-fecha">FECHA: __________________</span>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed, onMounted, ref } from 'vue'
import api, { mensajeError } from '../services/api'

const planillas = ref([])
const planillaId = ref(null)
const planillaActual = ref({ empresa: {} })
const papeletas = ref([])
const catalogo = ref([])
const seleccion = ref([])
const alerta = ref(null)

function mostrarAlerta(texto, tipo) {
  alerta.value = { texto, tipo }
  setTimeout(() => (alerta.value = null), 5000)
}

function fmt(v) {
  if (v === null || v === undefined) return '0,00'
  return Number(v).toLocaleString('es-BO', { minimumFractionDigits: 2, maximumFractionDigits: 2 })
}

function fmtFecha(s) {
  if (!s) return ''
  const [y, m, d] = String(s).split('-')
  return `${d}/${m}/${y}`
}

async function cargarPlanillas() {
  try {
    const { data } = await api.get('/planillas')
    planillas.value = data
  } catch (e) {
    mostrarAlerta(mensajeError(e), 'alert-danger')
  }
}

async function cargarCatalogo() {
  try {
    const { data } = await api.get('/conceptos')
    const haberes = data.filter((c) => c.tipo === 'HABER').sort((a, b) => a.orden - b.orden)
    const otros = data.filter((c) => c.tipo !== 'HABER').sort((a, b) => a.orden - b.orden)
    catalogo.value = [...haberes, ...otros]
  } catch (e) {
    mostrarAlerta(mensajeError(e), 'alert-danger')
  }
}

async function cargarPapeletas() {
  seleccion.value = []
  papeletas.value = []
  if (!planillaId.value) return
  try {
    const { data } = await api.get(`/planillas/${planillaId.value}/papeletas`)
    planillaActual.value = data.planilla || { empresa: {} }
    papeletas.value = data.papeletas || []
  } catch (e) {
    mostrarAlerta(mensajeError(e), 'alert-danger')
  }
}

function construirLineas(p) {
  const porCodigo = {}
  ;(p.lineas || []).forEach((l) => { porCodigo[l.codigo] = l.monto })
  return catalogo.value.map((c) => ({
    codigo: c.codigo,
    nombre: c.nombre,
    tipo: c.tipo,
    monto: porCodigo[c.codigo] ?? 0
  }))
}

const seleccionadas = computed(() =>
  papeletas.value
    .filter((p) => seleccion.value.includes(p.detalleId))
    .map((p) => ({ ...p, lineas: construirLineas(p) }))
)

const todosSeleccionados = computed(
  () => papeletas.value.length > 0 && seleccion.value.length === papeletas.value.length
)

function seleccionarTodos() {
  if (todosSeleccionados.value) {
    seleccion.value = []
  } else {
    seleccion.value = papeletas.value.map((p) => p.detalleId)
  }
}

function imprimir() {
  if (seleccionadas.value.length === 0) {
    mostrarAlerta('Seleccione al menos un empleado', 'alert-warning')
    return
  }
  window.print()
}

onMounted(() => {
  cargarPlanillas()
  cargarCatalogo()
})
</script>

<style scoped>
.papeleta-lista {
  max-height: 320px;
  overflow-y: auto;
  border: 1px solid #dee2e6;
  border-radius: 0.4rem;
  padding: 0.4rem;
}

.papeleta-opcion {
  display: flex;
  align-items: center;
  gap: 0.4rem;
  padding: 0.35rem 0.5rem;
  border-radius: 0.3rem;
  cursor: pointer;
}

.papeleta-opcion:hover {
  background: #f0f4f9;
}

.papeletas-print {
  max-width: 720px;
  margin: 0 auto;
}

.papeleta {
  width: 100%;
  background: #fff;
  border: 1px solid #b9c1cc;
  padding: 0.4in;
  margin-bottom: 1.5rem;
  font-family: 'Arial', sans-serif;
  color: #000;
}

.ph-cabecera {
  display: flex;
  justify-content: space-between;
  align-items: baseline;
  border-bottom: 2px solid #000;
  padding-bottom: 4px;
}

.ph-empresa {
  font-size: 10pt;
  font-weight: 700;
  letter-spacing: 0.02em;
}

.ph-titulo {
  font-size: 10pt;
  font-weight: 700;
}

.ph-fecha {
  font-size: 8pt;
}

.ph-empleado {
  display: flex;
  align-items: baseline;
  gap: 12px;
  padding: 6px 0 4px;
  border-bottom: 1px solid #000;
}

.ph-item {
  font-weight: 700;
  white-space: nowrap;
}

.ph-nombre {
  font-weight: 700;
  text-transform: uppercase;
}

.ph-doc {
  color: #333;
}

.ph-resumen {
  border-bottom: 1px solid #000;
}

.ph-resumen-labels,
.ph-resumen-valores {
  display: grid;
  grid-template-columns: 1fr 1.2fr 1.2fr 1.2fr;
  gap: 4px;
  padding: 1px 0;
}

.ph-resumen-labels {
  font-size: 6.5pt;
  text-align: right;
  color: #222;
}

.ph-resumen-valores {
  font-size: 9pt;
  font-weight: 700;
  text-align: right;
  border-bottom: 1px solid #000;
  padding-bottom: 2px;
}

.ph-lineas {
  display: grid;
  grid-template-columns: 1fr;
}

.ph-linea {
  display: grid;
  grid-template-columns: 3fr 1fr 1fr;
  text-align: right;
  font-size: 7.5pt;
  line-height: 1.2;
  padding: 0.5px 0;
  border-bottom: 0.5px dotted #888;
}

.ph-linea .ph-desc {
  text-align: left;
}

.ph-linea-cabecera {
  font-weight: 700;
  font-size: 7pt;
  border-bottom: 1px solid #000;
}

.ph-total-hd {
  font-weight: 700;
  border-bottom: 1px solid #000;
}

.ph-total-lq {
  font-weight: 700;
  background: #eee;
}

.ph-nota {
  text-align: center;
  font-size: 6.5pt;
  font-style: italic;
  padding: 3px 0;
}

.ph-firma {
  display: flex;
  align-items: center;
  gap: 10px;
  margin-top: 4px;
  font-size: 7pt;
  font-weight: 700;
}

.ph-firma-linea {
  flex: 1;
  border-bottom: 1px solid #000;
}
</style>
