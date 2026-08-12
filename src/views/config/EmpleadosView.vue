<template>
  <div>
    <div class="d-flex justify-content-between align-items-center mb-3">
      <h4 class="mb-0"><i class="bi bi-people me-2"></i>Empleados</h4>
      <button class="btn btn-primary" @click="nuevo">
        <i class="bi bi-person-plus me-1"></i>Nuevo Empleado
      </button>
    </div>

    <div v-if="alerta" class="alert" :class="alerta.tipo">{{ alerta.texto }}</div>

    <div class="card shadow-sm border-0">
      <div class="card-body">
        <div class="row mb-3">
          <div class="col-md-5">
            <div class="input-group">
              <span class="input-group-text"><i class="bi bi-search"></i></span>
              <input
                v-model="busqueda"
                class="form-control"
                placeholder="Buscar por apellido, nombre o documento..."
                @keyup.enter="cargar(0)"
              />
            </div>
          </div>
          <div class="col-md-3 d-flex align-items-end">
            <button class="btn btn-outline-primary" @click="cargar(0)">Buscar</button>
          </div>
        </div>

        <div class="table-responsive">
          <table class="table table-hover align-middle">
            <thead>
              <tr>
                <th>#</th>
                <th>Documento</th>
                <th>Apellidos y Nombres</th>
                <th>Cargo</th>
                <th>F. Ingreso</th>
                <th>Jornal Hora</th>
                <th>Sexo</th>
                <th class="text-end">Acciones</th>
              </tr>
            </thead>
            <tbody>
              <tr v-if="!cargando && empleados.length === 0">
                <td colspan="8" class="text-center text-muted py-4">
                  No se encontraron empleados.
                </td>
              </tr>
              <tr v-for="(emp, i) in empleados" :key="emp.id">
                <td>{{ (pagina - 1) * 10 + i + 1 }}</td>
                <td>
                  {{ emp.persona.tipoDocumento }} {{ emp.persona.nroDocumento }}
                  <span v-if="emp.origen" class="text-muted small">({{ emp.origen }})</span>
                </td>
                <td>{{ nombreCompleto(emp) }}</td>
                <td>{{ emp.cargo || '-' }}</td>
                <td>{{ emp.fechaIngreso || '-' }}</td>
                <td class="text-end">{{ fmtNumero(emp.jornalHora) }}</td>
                <td>{{ emp.persona.sexo || '-' }}</td>
                <td class="text-end">
                  <button class="btn btn-sm btn-outline-primary me-1" @click="editar(emp)">
                    <i class="bi bi-pencil"></i>
                  </button>
                  <button class="btn btn-sm btn-outline-danger" @click="eliminar(emp)">
                    <i class="bi bi-trash"></i>
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <div class="d-flex justify-content-between align-items-center">
          <span class="text-muted small">
            Página {{ pagina }} de {{ totalPaginas || 1 }} ({{ totalElementos }} registros)
          </span>
          <nav>
            <ul class="pagination pagination-sm mb-0">
              <li class="page-item" :class="{ disabled: pagina <= 1 }">
                <button class="page-link" @click="cargar(pagina - 2)">Anterior</button>
              </li>
              <li class="page-item disabled">
                <span class="page-link">{{ pagina }}</span>
              </li>
              <li class="page-item" :class="{ disabled: pagina >= totalPaginas }">
                <button class="page-link" @click="cargar(pagina)">Siguiente</button>
              </li>
            </ul>
          </nav>
        </div>
      </div>
    </div>

    <!-- Modal -->
    <div class="modal fade" id="modalEmpleado" tabindex="-1" data-bs-backdrop="static">
      <div class="modal-dialog modal-lg modal-dialog-scrollable">
        <div class="modal-content">
          <div class="modal-header">
            <h5 class="modal-title">
              {{ form.id ? 'Editar Empleado' : 'Nuevo Empleado' }}
            </h5>
            <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
          </div>
          <div class="modal-body">
            <h6 class="text-primary">Persona</h6>
            <div class="row g-3 mb-3">
              <template v-if="form.id">
                <div class="col-md-8">
                  <label class="form-label">Persona asignada</label>
                  <input :value="nombreCompleto(form)" class="form-control" disabled />
                </div>
                <div class="col-md-4">
                  <label class="form-label">Documento</label>
                  <input :value="form.persona.tipoDocumento + ' ' + form.persona.nroDocumento" class="form-control" disabled />
                </div>
              </template>
              <template v-else>
                <div class="col-md-6">
                  <label class="form-label">Buscar persona</label>
                  <input v-model="filtroPersona" class="form-control" placeholder="Filtrar por nombre o documento..." />
                </div>
                <div class="col-md-6">
                  <label class="form-label">Persona *</label>
                  <select v-model="form.personaId" class="form-select" required>
                    <option :value="null" disabled>-- Seleccionar persona --</option>
                    <option v-for="per in personasDisponibles" :key="per.id" :value="per.id">
                      {{ nombreCompleto(per) }} - {{ per.tipoDocumento }} {{ per.nroDocumento }}
                    </option>
                  </select>
                  <small v-if="personasDisponibles.length === 0" class="text-muted">
                    No hay personas disponibles. Registre primero una persona.
                  </small>
                </div>
              </template>
            </div>

            <h6 class="text-primary">Datos laborales</h6>
            <div class="row g-3 mb-3">
              <div class="col-md-4">
                <label class="form-label">Cargo</label>
                <input v-model="form.cargo" class="form-control" />
              </div>
              <div class="col-md-4">
                <label class="form-label">Clasificación laboral</label>
                <input v-model="form.clasificacionLaboral" class="form-control" />
              </div>
              <div class="col-md-2">
                <label class="form-label">Fecha de ingreso</label>
                <input v-model="form.fechaIngreso" type="date" class="form-control" />
              </div>
              <div class="col-md-2">
                <label class="form-label">Fecha de seguro</label>
                <input v-model="form.fechaSeguro" type="date" class="form-control" />
              </div>
              <div class="col-md-3">
                <label class="form-label">Origen / Extensión</label>
                <select v-model="form.origen" class="form-select">
                  <option value="CH">CH - Chuquisaca</option>
                  <option value="CB">CB - Cochabamba</option>
                  <option value="CBBA">CBBA</option>
                  <option value="LP">LP - La Paz</option>
                  <option value="PT">PT - Potosí</option>
                  <option value="PO">PO - Oruro</option>
                  <option value="">Otro</option>
                </select>
              </div>
              <div class="col-md-3">
                <label class="form-label">NUA/CUA</label>
                <input v-model="form.nuaCua" class="form-control" />
              </div>
              <div class="col-md-3">
                <label class="form-label">AFP</label>
                <select v-model="form.afp" class="form-select">
                  <option value="Gestora">Gestora</option>
                  <option value="Previsión">Previsión</option>
                  <option value="Futuro de Bolivia">Futuro de Bolivia</option>
                  <option value="">Otra</option>
                </select>
              </div>
              <div class="col-md-3">
                <label class="form-label">Jubilado</label>
                <select v-model="form.jubilado" class="form-select">
                  <option :value="false">No</option>
                  <option :value="true">Sí</option>
                </select>
              </div>
              <div class="col-md-3">
                <label class="form-label">Jornal hora (Bs) *</label>
                <input v-model="form.jornalHora" type="number" step="0.01" min="0" class="form-control" required />
              </div>
            </div>
          </div>
          <div class="modal-footer">
            <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancelar</button>
            <button class="btn btn-primary" :disabled="guardando" @click="guardar">
              <span v-if="guardando" class="spinner-border spinner-border-sm me-1"></span>
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
import api, { mensajeError } from '../../services/api'

const empleados = ref([])
const personasDisponibles = ref([])
const cargando = ref(false)
const guardando = ref(false)
const busqueda = ref('')
const filtroPersona = ref('')
const pagina = ref(1)
const totalPaginas = ref(0)
const totalElementos = ref(0)
const alerta = ref(null)

const empleadoVacio = () => ({
  id: null,
  personaId: null,
  afp: 'Gestora',
  nuaCua: '',
  fechaIngreso: '',
  fechaSeguro: '',
  origen: 'CH',
  cargo: '',
  clasificacionLaboral: '',
  jubilado: false,
  jornalHora: 0,
  persona: { tipoDocumento: 'CI', nroDocumento: '' }
})

const form = reactive(empleadoVacio())

const personasFiltradas = computed(() => {
  const q = filtroPersona.value.trim().toLowerCase()
  if (!q) return personasDisponibles.value
  return personasDisponibles.value.filter((per) =>
    (nombreCompleto(per) + ' ' + per.tipoDocumento + ' ' + per.nroDocumento).toLowerCase().includes(q)
  )
})

let modal = null

function mostrarAlerta(texto, tipo) {
  alerta.value = { texto, tipo }
  setTimeout(() => (alerta.value = null), 4000)
}

function nombreCompleto(emp) {
  const p = emp.persona || emp
  return [p.apellidoPaterno, p.apellidoMaterno, p.apellidoCasada, p.nombres]
    .filter(Boolean)
    .map((x) => x.trim())
    .join(' ') || p.nroDocumento
}

function fmtNumero(v) {
  if (v === null || v === undefined) return '-'
  return Number(v).toLocaleString('es-BO', { minimumFractionDigits: 2, maximumFractionDigits: 2 })
}

async function cargar(p) {
  if (p < 0) return
  cargando.value = true
  try {
    const { data } = await api.get('/empleados', {
      params: { page: p, size: 10, q: busqueda.value || undefined }
    })
    empleados.value = data.content
    pagina.value = data.number + 1
    totalPaginas.value = data.totalPages
    totalElementos.value = data.totalElements
  } catch (e) {
    mostrarAlerta(mensajeError(e), 'alert-danger')
  } finally {
    cargando.value = false
  }
}

async function cargarDisponibles() {
  try {
    const { data } = await api.get('/personas/disponibles')
    personasDisponibles.value = data
  } catch (e) {
    mostrarAlerta(mensajeError(e), 'alert-danger')
  }
}

function nuevo() {
  Object.assign(form, empleadoVacio())
  filtroPersona.value = ''
  cargarDisponibles()
  modal.show()
}

function editar(emp) {
  Object.assign(form, empleadoVacio(), emp)
  modal.show()
}

async function guardar() {
  if (!form.id && !form.personaId) {
    mostrarAlerta('Seleccione una persona', 'alert-warning')
    return
  }
  guardando.value = true
  try {
    if (form.id) {
      await api.put(`/empleados/${form.id}`, form)
    } else {
      await api.post('/empleados', form)
    }
    modal.hide()
    mostrarAlerta('Empleado guardado correctamente', 'alert-success')
    cargar(pagina.value - 1)
  } catch (e) {
    mostrarAlerta(mensajeError(e), 'alert-danger')
  } finally {
    guardando.value = false
  }
}

async function eliminar(emp) {
  if (!confirm(`¿Eliminar a ${nombreCompleto(emp)}?`)) return
  try {
    await api.delete(`/empleados/${emp.id}`)
    mostrarAlerta('Empleado eliminado', 'alert-success')
    cargar(pagina.value - 1)
  } catch (e) {
    mostrarAlerta(mensajeError(e), 'alert-danger')
  }
}

onMounted(() => {
  modal = new Modal(document.getElementById('modalEmpleado'))
  cargar(0)
  cargarDisponibles()
})
</script>
