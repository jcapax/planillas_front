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
                  <button class="btn btn-sm btn-outline-primary me-1" @click="verDetalles(p)">
                    <i class="bi bi-list-ol"></i>
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
            <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
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
              Descuentos variables: {{ detalleDescuentoEmpleado }}
            </h5>
            <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
          </div>
          <div class="modal-body">
            <p class="text-muted small">
              Descuentos variables de este empleado para la planilla
              <strong>{{ detalleActual }}</strong>. Los descuentos fijos se aplican
              automáticamente a todos los empleados.
            </p>
            <div class="table-responsive">
              <table class="table table-sm table-hover align-middle">
                <thead>
                  <tr>
                    <th>Código</th>
                    <th>Descuento</th>
                    <th style="width: 180px" class="text-end">Monto (Bs)</th>
                  </tr>
                </thead>
                <tbody>
                  <tr v-for="d in detalleDescuentos" :key="d.conceptoId">
                    <td><code>{{ d.codigo }}</code></td>
                    <td>{{ d.nombre }}</td>
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
const alerta = ref(null)
const detalleActual = ref('')
const detallePlanillaId = ref(null)
const detalleSeleccionado = ref(null)
const detalleDescuentoEmpleado = ref('')
const detalleDescuentos = ref([])
const guardandoDescuentos = ref(false)

let modalDetalles = null
let modalDetalleDescuentos = null

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
    mostrarAlerta('Descuentos guardados y totales recalculados', 'alert-success')
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

onMounted(() => {
  modalDetalles = new Modal(document.getElementById('modalDetalles'))
  modalDetalleDescuentos = new Modal(document.getElementById('modalDetalleDescuentos'))
  cargar()
})
</script>
