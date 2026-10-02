<template>
  <div>
    <div class="d-flex justify-content-between align-items-center mb-3">
      <h4 class="mb-0"><i class="bi bi-file-earmark-spreadsheet me-2"></i>Gestión de Planillas</h4>
    </div>

    <div v-if="alerta" class="alert" :class="alerta.tipo">{{ alerta.texto }}</div>

    <div class="card shadow-sm border-0 mb-3">
      <div class="card-header">Nueva planilla</div>
      <div class="card-body">
        <div class="row g-2 align-items-end">
          <div class="col-md-3">
            <label class="form-label">Mes</label>
            <select v-model="nuevaMes" class="form-select">
              <option v-for="(m, i) in meses" :key="i" :value="i + 1">{{ m }}</option>
            </select>
          </div>
          <div class="col-md-3">
            <label class="form-label">Año</label>
            <input v-model="nuevaAnio" type="number" class="form-control" />
          </div>
          <div class="col-md-3">
            <button class="btn btn-primary" :disabled="creando" @click="crear">
              <span v-if="creando" class="spinner-border spinner-border-sm me-1"></span>
              <i class="bi bi-plus-circle me-1"></i>Crear Planilla
            </button>
          </div>
        </div>
      </div>
    </div>

    <div class="card shadow-sm border-0">
      <div class="card-header">Planillas existentes</div>
      <div class="card-body">
        <div class="table-responsive">
          <table class="table table-hover align-middle">
            <thead>
              <tr>
                <th>#</th>
                <th>Nombre</th>
                <th class="text-end">Total Haberes</th>
                <th class="text-end">Total Descuentos</th>
                <th class="text-end">Líquido Pagable</th>
                <th>Estado</th>
                <th class="text-end">Acciones</th>
              </tr>
            </thead>
            <tbody>
              <tr v-if="planillas.length === 0">
                <td colspan="7" class="text-center text-muted py-4">No hay planillas.</td>
              </tr>
              <tr v-for="p in planillas" :key="p.id">
                <td>{{ p.id }}</td>
                <td>{{ p.nombre }}</td>
                <td class="text-end">{{ fmt(p.totalHaberes) }}</td>
                <td class="text-end">{{ fmt(p.totalDescuentos) }}</td>
                <td class="text-end fw-bold">{{ fmt(p.totalLiquido) }}</td>
                <td>
                  <span class="badge" :class="p.estado === 'CERRADA' ? 'bg-success' : 'bg-warning text-dark'">
                    {{ p.estado }}
                  </span>
                </td>
                <td class="text-end">
                  <button class="btn btn-sm btn-outline-success me-1" @click="generar(p)">
                    <i class="bi bi-calculator me-1"></i>Generar
                  </button>
                  <button
                    class="btn btn-sm btn-outline-info me-1"
                    :disabled="recalculandoId === p.id"
                    @click="recalcular(p)"
                    title="Volver a calcular total aportes, descuentos varios, total descuentos y líquido pagable"
                  >
                    <span v-if="recalculandoId === p.id" class="spinner-border spinner-border-sm me-1"></span>
                    <i v-else class="bi bi-arrow-repeat me-1"></i>Recalcular
                  </button>
                  <button class="btn btn-sm btn-outline-primary me-1" @click="verDetalles(p)" title="Ver detalle">
                    <i class="bi bi-list-ol"></i>
                  </button>
                  <button class="btn btn-sm btn-outline-warning me-1" @click="abrirMatriz(p)" title="Registro masivo de descuentos (tabla Excel)">
                    <i class="bi bi-table me-1"></i>Matriz
                  </button>
                  <button class="btn btn-sm btn-outline-danger" @click="eliminar(p)">
                    <i class="bi bi-trash"></i>
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>

    <!-- Modal detalles -->
    <div class="modal fade" id="modalDetalles" tabindex="-1">
      <div class="modal-dialog modal-xl modal-dialog-scrollable">
        <div class="modal-content">
          <div class="modal-header">
            <h5 class="modal-title">Detalles: {{ detalleActual }}</h5>
            <div class="d-flex gap-2 align-items-center">
              <button v-if="detallePlanillaId" type="button" class="btn btn-sm btn-info" :disabled="recalculandoId === detallePlanillaId" @click="recalcularDesdeDetalle">
                <span v-if="recalculandoId === detallePlanillaId" class="spinner-border spinner-border-sm me-1"></span>
                <i v-else class="bi bi-arrow-repeat me-1"></i>Recalcular
              </button>
              <button v-if="detallePlanillaId" type="button" class="btn btn-sm btn-warning" @click="abrirMatrizDesdeDetalle">
                <i class="bi bi-table me-1"></i>Registro masivo (Excel)
              </button>
              <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
          </div>
          <div class="modal-body">
            <div class="table-responsive">
              <table class="table table-sm table-striped">
                <thead>
                  <tr>
                    <th>#</th>
                    <th>Empleado</th>
                    <th class="text-end">Horas</th>
                    <th class="text-end">Haber Básico</th>
                    <th class="text-end">Bono Antig.</th>
                    <th class="text-end">Dominical</th>
                    <th class="text-end">Total Ganado</th>
                    <th class="text-end">Aportes</th>
                    <th class="text-end">Dctos. Variables</th>
                    <th class="text-end">Total Descuentos</th>
                    <th class="text-end">Líquido</th>
                    <th class="text-end">Acciones</th>
                  </tr>
                </thead>
                <tbody>
                  <tr v-if="detalles.length === 0">
                    <td colspan="12" class="text-center text-muted py-3">
                      La planilla aún no ha sido generada.
                    </td>
                  </tr>
                  <tr v-for="d in detalles" :key="d.id">
                    <td>{{ d.item }}</td>
                    <td>{{ d.empleado ? nombreEmpleado(d.empleado) : '' }}</td>
                    <td class="text-end">{{ d.horasTrabajadas }}</td>
                    <td class="text-end">{{ fmt(d.haberBasico) }}</td>
                    <td class="text-end">{{ fmt(d.bonoAntigMonto) }}</td>
                    <td class="text-end">{{ fmt(d.salarioDominical) }}</td>
                    <td class="text-end fw-bold">{{ fmt(d.totalGanado) }}</td>
                    <td class="text-end">{{ fmt(d.totalAportes) }}</td>
                    <td class="text-end">{{ fmt(d.descuentosVarios) }}</td>
                    <td class="text-end">{{ fmt(d.totalDescuentos) }}</td>
                    <td class="text-end fw-bold">{{ fmt(d.liquidoPagable) }}</td>
                    <td class="text-end">
                      <button class="btn btn-sm btn-outline-warning" @click="abrirDescuentos(d)">
                        <i class="bi bi-pencil-square me-1"></i>Dctos.
                      </button>
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Modal descuentos variables por empleado -->
    <div class="modal fade" id="modalDetalleDescuentos" tabindex="-1" data-bs-backdrop="static">
      <div class="modal-dialog modal-lg modal-dialog-scrollable">
        <div class="modal-content">
          <div class="modal-header">
            <h5 class="modal-title">
              Ingresos y descuentos: {{ detalleDescuentoEmpleado }}
            </h5>
            <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
          </div>
          <div class="modal-body">
            <p class="text-muted small">
              Ingresos y descuentos variables de este empleado para la planilla
              <strong>{{ detalleActual }}</strong>. Los descuentos fijos y los conceptos
              calculados por el sistema se aplican automáticamente.
            </p>
            <div class="table-responsive">
              <table class="table table-sm table-hover align-middle">
                <thead>
                  <tr>
                    <th>Código</th>
                    <th>Concepto</th>
                    <th>Tipo</th>
                    <th style="width: 180px" class="text-end">Monto (Bs)</th>
                  </tr>
                </thead>
                <tbody>
                  <tr v-for="d in detalleDescuentos" :key="d.conceptoId">
                    <td><code>{{ d.codigo }}</code></td>
                    <td>{{ d.nombre }}</td>
                    <td><span class="badge" :class="badgeTipo(d.tipo)">{{ d.tipo }}</span></td>
                    <td>
                      <input v-model="d.monto" type="number" step="0.01" min="0" class="form-control form-control-sm text-end" />
                    </td>
                  </tr>
                </tbody>
                <tfoot>
                  <tr>
                    <td colspan="2" class="text-end fw-bold">Total</td>
                    <td class="text-end fw-bold">{{ fmt(detalleDescuentosTotal) }}</td>
                  </tr>
                </tfoot>
              </table>
            </div>
          </div>
          <div class="modal-footer">
            <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancelar</button>
            <button class="btn btn-primary" :disabled="guardandoDescuentos" @click="guardarDescuentos">
              <span v-if="guardandoDescuentos" class="spinner-border spinner-border-sm me-1"></span>
              Guardar
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- Modal matriz masiva estilo Excel -->
    <div class="modal fade" id="modalMatrizDescuentos" tabindex="-1" data-bs-backdrop="static">
      <div class="modal-dialog modal-fullscreen">
        <div class="modal-content">
          <div class="modal-header">
            <h5 class="modal-title">
              <i class="bi bi-table me-2"></i>Registro masivo de ingresos y descuentos: {{ matrizPlanillaNombre }}
            </h5>
            <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
          </div>
          <div class="modal-body">
            <p class="text-muted small mb-2">
              Todos los empleados en filas y los tipos de ingreso o descuento en columnas paralelas,
              como una planilla Excel. Edite los montos (Bs) y pulse <strong>Guardar todo</strong>.
              Los haberes suman al total ganado y los descuentos restan; los totales por empleado
              y por concepto se recalculan automáticamente.
            </p>
            <div class="row g-2 align-items-center mb-2">
              <div class="col-md-3">
                <select v-model="matrizTipos" class="form-select form-select-sm" @change="cambiarTipoMatriz">
                  <option value="">Todos (ingresos y descuentos)</option>
                  <option value="HABER">Ingresos (HABER)</option>
                  <option value="DESCUENTO">Descuentos (DESCUENTO)</option>
                  <option value="APORTE">Aportes (APORTE)</option>
                </select>
              </div>
              <div class="col-md-4">
                <div class="input-group input-group-sm">
                  <span class="input-group-text"><i class="bi bi-search"></i></span>
                  <input v-model="matrizFiltro" type="text" class="form-control" placeholder="Filtrar empleado..." />
                </div>
              </div>
              <div class="col-md-5 text-md-end text-muted small">
                <span v-if="matrizCargando" class="spinner-border spinner-border-sm me-2"></span>
                {{ matrizFilasFiltradas.length }} empleados
                · {{ matrizConceptos.length }} conceptos
                · Haberes: <strong>{{ fmt(matrizGrupoTotal('HABER')) }}</strong>
                · Dctos.: <strong>{{ fmt(matrizGrupoTotal('DESCUENTO')) }}</strong>
              </div>
            </div>
            <div v-if="matrizConceptos.length === 0 && !matrizCargando" class="alert alert-warning">
              No hay conceptos para este filtro. Cree los tipos de ingreso o descuento en
              Configuración → Conceptos.
            </div>
            <div class="table-responsive matriz-excel">
              <table class="table table-sm table-bordered table-hover align-middle mb-0">
                <thead class="table-light">
                  <tr>
                    <th class="sticky-col bg-light">#</th>
                    <th class="sticky-emp bg-light" style="min-width: 240px">Empleado</th>
                    <th v-for="c in matrizConceptos" :key="c.id" class="text-center" style="min-width: 140px">
                      <div><span class="badge" :class="badgeTipo(c.tipo)">{{ c.tipo }}</span></div>
                      <div class="fw-bold">{{ c.codigo }}</div>
                      <div class="fw-normal text-muted excel-nombre">{{ c.nombre }}</div>
                    </th>
                    <th v-if="matrizTiene('HABER')" class="text-end bg-light" style="min-width: 110px">Haberes</th>
                    <th v-if="matrizTiene('DESCUENTO')" class="text-end bg-light" style="min-width: 110px">Dctos.</th>
                    <th v-if="matrizTiene('APORTE')" class="text-end bg-light" style="min-width: 110px">Aportes</th>
                    <th class="text-end bg-light" style="min-width: 120px">Neto fila</th>
                  </tr>
                </thead>
                <tbody>
                  <tr v-if="matrizFilasFiltradas.length === 0">
                    <td :colspan="matrizConceptos.length + 6" class="text-center text-muted py-4">
                      {{ matrizCargando ? 'Cargando...' : 'Sin empleados en esta planilla. Genere la planilla primero.' }}
                    </td>
                  </tr>
                  <tr v-for="f in matrizFilasFiltradas" :key="f.detalleId">
                    <td class="sticky-col text-muted">{{ f.item }}</td>
                    <td class="sticky-emp">
                      <div class="fw-semibold">{{ f.nombre }}</div>
                      <div class="text-muted small">{{ f.documento }}</div>
                    </td>
                    <td v-for="c in matrizConceptos" :key="c.id" class="p-1">
                      <input
                        v-model.number="f.montos[c.id]"
                        type="number"
                        step="0.01"
                        min="0"
                        class="form-control form-control-sm text-end excel-cell"
                        @focus="$event.target.select()"
                      />
                    </td>
                    <td v-if="matrizTiene('HABER')" class="text-end text-success fw-semibold">{{ fmt(filaSubtotal(f, 'HABER')) }}</td>
                    <td v-if="matrizTiene('DESCUENTO')" class="text-end text-danger fw-semibold">{{ fmt(filaSubtotal(f, 'DESCUENTO')) }}</td>
                    <td v-if="matrizTiene('APORTE')" class="text-end text-info fw-semibold">{{ fmt(filaSubtotal(f, 'APORTE')) }}</td>
                    <td class="text-end fw-bold">{{ fmt(filaNeto(f)) }}</td>
                  </tr>
                </tbody>
                <tfoot v-if="matrizFilasFiltradas.length > 0" class="table-light">
                  <tr>
                    <td colspan="2" class="text-end fw-bold sticky-col">Total columna</td>
                    <td v-for="c in matrizConceptos" :key="c.id" class="text-end fw-bold">
                      {{ fmt(columnaTotal(c.id)) }}
                    </td>
                    <td v-if="matrizTiene('HABER')" class="text-end fw-bold text-success">{{ fmt(matrizGrupoTotal('HABER')) }}</td>
                    <td v-if="matrizTiene('DESCUENTO')" class="text-end fw-bold text-danger">{{ fmt(matrizGrupoTotal('DESCUENTO')) }}</td>
                    <td v-if="matrizTiene('APORTE')" class="text-end fw-bold text-info">{{ fmt(matrizGrupoTotal('APORTE')) }}</td>
                    <td class="text-end fw-bold">{{ fmt(matrizNetoTotal) }}</td>
                  </tr>
                </tfoot>
              </table>
            </div>
          </div>
          <div class="modal-footer">
            <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cerrar</button>
            <button class="btn btn-primary" :disabled="matrizGuardando || matrizConceptos.length === 0" @click="guardarMatriz">
              <span v-if="matrizGuardando" class="spinner-border spinner-border-sm me-1"></span>
              <i v-else class="bi bi-save me-1"></i>Guardar todo
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed, onMounted, reactive, ref } from 'vue'
import { Modal } from 'bootstrap'
import api, { mensajeError } from '../services/api'

const meses = ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
  'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre']

const planillas = ref([])
const detalles = ref([])
const nuevaMes = ref(7)
const nuevaAnio = ref(new Date().getFullYear())
const creando = ref(false)
const recalculandoId = ref(null)
const alerta = ref(null)
const detalleActual = ref('')
const detallePlanillaId = ref(null)
const detalleSeleccionado = ref(null)
const detalleDescuentoEmpleado = ref('')
const detalleDescuentos = ref([])
const guardandoDescuentos = ref(false)

// --- Matriz masiva estilo Excel ---
const matrizPlanillaId = ref(null)
const matrizPlanillaNombre = ref('')
const matrizConceptos = ref([])
const matrizFilas = ref([])
const matrizFiltro = ref('')
const matrizTipos = ref('')
const matrizCargando = ref(false)
const matrizGuardando = ref(false)

let modalDetalles = null
let modalDetalleDescuentos = null
let modalMatriz = null

function mostrarAlerta(texto, tipo) {
  alerta.value = { texto, tipo }
  setTimeout(() => (alerta.value = null), 5000)
}

function fmt(v) {
  if (v === null || v === undefined) return '0,00'
  return Number(v).toLocaleString('es-BO', { minimumFractionDigits: 2, maximumFractionDigits: 2 })
}

const detalleDescuentosTotal = computed(() =>
  detalleDescuentos.value.reduce((acc, d) => acc + (Number(d.monto) || 0), 0)
)

const matrizFilasFiltradas = computed(() => {
  const q = matrizFiltro.value.trim().toLowerCase()
  if (!q) return matrizFilas.value
  return matrizFilas.value.filter((f) =>
    (f.nombre || '').toLowerCase().includes(q) ||
    (f.documento || '').toLowerCase().includes(q)
  )
})

const matrizGranTotal = computed(() =>
  matrizFilas.value.reduce((acc, f) => acc + filaTotal(f), 0)
)

const matrizGranTotalFiltrado = computed(() =>
  matrizFilasFiltradas.value.reduce((acc, f) => acc + filaTotal(f), 0)
)

const matrizNetoTotal = computed(() =>
  matrizGrupoTotal('HABER') - matrizGrupoTotal('DESCUENTO') - matrizGrupoTotal('APORTE')
)

function badgeTipo(tipo) {
  return {
    HABER: 'bg-success',
    APORTE: 'bg-info text-dark',
    DESCUENTO: 'bg-warning text-dark'
  }[tipo] || 'bg-secondary'
}

function matrizTiene(tipo) {
  return matrizConceptos.value.some((c) => c.tipo === tipo)
}

function filaSubtotal(f, tipo) {
  return matrizConceptos.value
    .filter((c) => c.tipo === tipo)
    .reduce((acc, c) => acc + (Number(f.montos[c.id]) || 0), 0)
}

function filaNeto(f) {
  return filaSubtotal(f, 'HABER') - filaSubtotal(f, 'DESCUENTO') - filaSubtotal(f, 'APORTE')
}

function matrizGrupoTotal(tipo) {
  const ids = new Set(matrizConceptos.value.filter((c) => c.tipo === tipo).map((c) => c.id))
  return matrizFilasFiltradas.value.reduce(
    (acc, f) => acc + Object.entries(f.montos || {})
      .reduce((a, [k, v]) => a + (ids.has(Number(k)) ? Number(v) || 0 : 0), 0),
    0
  )
}

function filaTotal(f) {
  return matrizConceptos.value.reduce((acc, c) => acc + (Number(f.montos[c.id]) || 0), 0)
}

function columnaTotal(conceptoId) {
  return matrizFilasFiltradas.value.reduce((acc, f) => acc + (Number(f.montos[conceptoId]) || 0), 0)
}

function nombreEmpleado(emp) {
  const p = emp.persona || emp
  return [p.apellidoPaterno, p.apellidoMaterno, p.apellidoCasada, p.nombres]
    .filter(Boolean).map((x) => x.trim()).join(' ') || p.nroDocumento
}

async function cargar() {
  try {
    const { data } = await api.get('/planillas')
    planillas.value = data
  } catch (e) {
    mostrarAlerta(mensajeError(e), 'alert-danger')
  }
}

async function crear() {
  creando.value = true
  try {
    await api.post('/planillas', null, {
      params: { anio: nuevaAnio.value, mes: nuevaMes.value }
    })
    mostrarAlerta('Planilla creada', 'alert-success')
    cargar()
  } catch (e) {
    mostrarAlerta(mensajeError(e), 'alert-danger')
  } finally {
    creando.value = false
  }
}

async function generar(p) {
  if (!confirm(`¿Generar el cálculo de "${p.nombre}" con los empleados activos?`)) return
  try {
    const { data } = await api.post(`/planillas/${p.id}/generar`)
    mostrarAlerta(`Planilla generada. Líquido: ${fmt(data.totalLiquido)}`, 'alert-success')
    cargar()
  } catch (e) {
    mostrarAlerta(mensajeError(e), 'alert-danger')
  }
}

async function recalcular(p) {
  if (!confirm(`¿Recalcular los totales de "${p.nombre}"? Se actualizarán total aportes, descuentos varios, total descuentos y líquido pagable de cada empleado a partir de los conceptos guardados.`)) return
  recalculandoId.value = p.id
  try {
    const { data } = await api.post(`/planillas/${p.id}/recalcular`)
    mostrarAlerta(`Totales recalculados. Líquido: ${fmt(data.totalLiquido)}`, 'alert-success')
    cargar()
    if (detallePlanillaId.value === p.id) {
      const { data: det } = await api.get(`/planillas/${p.id}/detalles`)
      detalles.value = det
    }
  } catch (e) {
    mostrarAlerta(mensajeError(e), 'alert-danger')
  } finally {
    recalculandoId.value = null
  }
}

function recalcularDesdeDetalle() {
  if (!detallePlanillaId.value) return
  recalcular({ id: detallePlanillaId.value, nombre: detalleActual.value })
}

async function verDetalles(p) {
  detalleActual.value = p.nombre
  detallePlanillaId.value = p.id
  try {
    const { data } = await api.get(`/planillas/${p.id}/detalles`)
    detalles.value = data
  } catch (e) {
    mostrarAlerta(mensajeError(e), 'alert-danger')
  }
  modalDetalles.show()
}

async function abrirDescuentos(d) {
  detalleSeleccionado.value = d
  detalleDescuentoEmpleado.value = d.empleado ? nombreEmpleado(d.empleado) : `Empleado #${d.empleado_id}`
  try {
    const { data } = await api.get(`/planillas/detalles/${d.id}/descuentos`)
    detalleDescuentos.value = data.map((x) => ({ ...x, monto: Number(x.monto) }))
  } catch (e) {
    mostrarAlerta(mensajeError(e), 'alert-danger')
  }
  modalDetalleDescuentos.show()
}

async function guardarDescuentos() {
  const d = detalleSeleccionado.value
  if (!d) return
  guardandoDescuentos.value = true
  try {
    const payload = detalleDescuentos.value.map((x) => ({
      conceptoId: x.conceptoId,
      monto: Number(x.monto) || 0
    }))
    await api.put(`/planillas/detalles/${d.id}/descuentos`, payload)
    modalDetalleDescuentos.hide()
    mostrarAlerta('Conceptos guardados y totales recalculados', 'alert-success')
    if (detallePlanillaId.value) {
      await verDetalles({ id: detallePlanillaId.value, nombre: detalleActual.value })
    }
    cargar()
  } catch (e) {
    mostrarAlerta(mensajeError(e), 'alert-danger')
  } finally {
    guardandoDescuentos.value = false
  }
}

async function eliminar(p) {
  if (!confirm(`¿Eliminar la planilla "${p.nombre}"?`)) return
  try {
    await api.delete(`/planillas/${p.id}`)
    mostrarAlerta('Planilla eliminada', 'alert-success')
    cargar()
  } catch (e) {
    mostrarAlerta(mensajeError(e), 'alert-danger')
  }
}

async function abrirMatriz(p) {
  matrizPlanillaId.value = p.id
  matrizPlanillaNombre.value = p.nombre
  matrizFiltro.value = ''
  matrizConceptos.value = []
  matrizFilas.value = []
  modalMatriz.show()
  await cargarMatrizPlanilla()
}

async function cargarMatrizPlanilla() {
  if (!matrizPlanillaId.value) return
  matrizCargando.value = true
  try {
    const { data } = await api.get(`/planillas/${matrizPlanillaId.value}/descuentos-matriz`, {
      params: { tipos: matrizTipos.value || undefined }
    })
    matrizConceptos.value = data.conceptos || []
    matrizFilas.value = (data.filas || []).map((f) => {
      const montos = {}
      for (const [k, v] of Object.entries(f.montos || {})) {
        montos[k] = Number(v) || 0
      }
      return { ...f, montos }
    })
  } catch (e) {
    mostrarAlerta(mensajeError(e), 'alert-danger')
  } finally {
    matrizCargando.value = false
  }
}

function cambiarTipoMatriz() {
  cargarMatrizPlanilla()
}

function abrirMatrizDesdeDetalle() {
  if (!detallePlanillaId.value) return
  abrirMatriz({ id: detallePlanillaId.value, nombre: detalleActual.value })
}

async function guardarMatriz() {
  if (!matrizPlanillaId.value) return
  matrizGuardando.value = true
  try {
    const payload = []
    for (const f of matrizFilas.value) {
      for (const c of matrizConceptos.value) {
        payload.push({
          detalleId: f.detalleId,
          conceptoId: c.id,
          monto: Number(f.montos[c.id]) || 0
        })
      }
    }
    await api.put(`/planillas/${matrizPlanillaId.value}/descuentos-matriz`, payload)
    modalMatriz.hide()
    mostrarAlerta('Conceptos masivos guardados y totales recalculados', 'alert-success')
    verDetalles({ id: matrizPlanillaId.value, nombre: matrizPlanillaNombre.value })
    cargar()
  } catch (e) {
    mostrarAlerta(mensajeError(e), 'alert-danger')
  } finally {
    matrizGuardando.value = false
  }
}

onMounted(() => {
  modalDetalles = new Modal(document.getElementById('modalDetalles'))
  modalDetalleDescuentos = new Modal(document.getElementById('modalDetalleDescuentos'))
  modalMatriz = new Modal(document.getElementById('modalMatrizDescuentos'))
  cargar()
})
</script>

<style scoped>
.matriz-excel {
  max-height: 60vh;
}
.matriz-excel thead th {
  position: sticky;
  top: 0;
  z-index: 3;
}
.excel-cell {
  min-width: 110px;
}
.excel-cell:focus {
  border-color: #198754;
  box-shadow: 0 0 0 0.15rem rgba(25, 135, 84, 0.25);
}
.excel-nombre {
  font-size: 0.72rem;
  max-width: 160px;
  white-space: normal;
}
.sticky-emp {
  position: sticky;
  left: 0;
  z-index: 2;
  background: #fff;
}
thead .sticky-emp {
  z-index: 4;
}
</style>
