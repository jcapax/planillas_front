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
                    <th class="text-end">Descuentos</th>
                    <th class="text-end">Líquido</th>
                  </tr>
                </thead>
                <tbody>
                  <tr v-if="detalles.length === 0">
                    <td colspan="10" class="text-center text-muted py-3">
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
                    <td class="text-end">{{ fmt(d.totalDescuentos) }}</td>
                    <td class="text-end fw-bold">{{ fmt(d.liquidoPagable) }}</td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { onMounted, reactive, ref } from 'vue'
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

let modalDetalles = null

function mostrarAlerta(texto, tipo) {
  alerta.value = { texto, tipo }
  setTimeout(() => (alerta.value = null), 5000)
}

function fmt(v) {
  if (v === null || v === undefined) return '0,00'
  return Number(v).toLocaleString('es-BO', { minimumFractionDigits: 2, maximumFractionDigits: 2 })
}

function nombreEmpleado(emp) {
  return [emp.apellidoPaterno, emp.apellidoMaterno, emp.nombre1, emp.otrosNombres]
    .filter(Boolean).map((x) => x.trim()).join(' ') || emp.nroDocumento
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
  try {
    const { data } = await api.get(`/planillas/${p.id}/detalles`)
    detalles.value = data
  } catch (e) {
    mostrarAlerta(mensajeError(e), 'alert-danger')
  }
  modalDetalles.show()
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
  cargar()
})
</script>
