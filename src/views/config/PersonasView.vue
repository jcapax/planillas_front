<template>
  <div>
    <div class="d-flex justify-content-between align-items-center mb-3">
      <h4 class="mb-0"><i class="bi bi-person-vcard me-2"></i>Personas</h4>
      <button class="btn btn-primary" @click="nuevo">
        <i class="bi bi-person-plus me-1"></i>Nueva Persona
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
                <th>Sexo</th>
                <th>F. Nacimiento</th>
                <th>Teléfono</th>
                <th class="text-end">Acciones</th>
              </tr>
            </thead>
            <tbody>
              <tr v-if="!cargando && personas.length === 0">
                <td colspan="7" class="text-center text-muted py-4">
                  No se encontraron personas.
                </td>
              </tr>
              <tr v-for="(per, i) in personas" :key="per.id">
                <td>{{ (pagina - 1) * 10 + i + 1 }}</td>
                <td>{{ per.tipoDocumento }} {{ per.nroDocumento }}</td>
                <td>{{ nombreCompleto(per) }}</td>
                <td>{{ per.sexo || '-' }}</td>
                <td>{{ per.fechaNacimiento || '-' }}</td>
                <td>{{ per.telefono || '-' }}</td>
                <td class="text-end">
                  <button class="btn btn-sm btn-outline-primary me-1" @click="editar(per)">
                    <i class="bi bi-pencil"></i>
                  </button>
                  <button class="btn btn-sm btn-outline-danger" @click="eliminar(per)">
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
    <div class="modal fade" id="modalPersona" tabindex="-1" data-bs-backdrop="static">
      <div class="modal-dialog modal-lg modal-dialog-scrollable">
        <div class="modal-content">
          <div class="modal-header">
            <h5 class="modal-title">
              {{ form.id ? 'Editar Persona' : 'Nueva Persona' }}
            </h5>
            <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
          </div>
          <div class="modal-body">
            <h6 class="text-primary">Identificación</h6>
            <div class="row g-3 mb-3">
              <div class="col-md-3">
                <label class="form-label">Tipo documento</label>
                <select v-model="form.tipoDocumento" class="form-select">
                  <option value="CI">CI</option>
                  <option value="RUN">RUN</option>
                  <option value="Pasaporte">Pasaporte</option>
                  <option value="Carnet de Extranjero">Carnet de Extranjero</option>
                  <option value="Otro">Otro</option>
                </select>
              </div>
              <div class="col-md-3">
                <label class="form-label">Número documento *</label>
                <input v-model="form.nroDocumento" class="form-control" required />
              </div>
            </div>

            <h6 class="text-primary">Datos personales</h6>
            <div class="row g-3 mb-3">
              <div class="col-md-6">
                <label class="form-label">Apellido Paterno</label>
                <input v-model="form.apellidoPaterno" class="form-control" />
              </div>
              <div class="col-md-6">
                <label class="form-label">Apellido Materno</label>
                <input v-model="form.apellidoMaterno" class="form-control" />
              </div>
              <div class="col-md-6">
                <label class="form-label">Apellido de casada</label>
                <input v-model="form.apellidoCasada" class="form-control" />
              </div>
              <div class="col-md-6">
                <label class="form-label">Nombres</label>
                <input v-model="form.nombres" class="form-control" />
              </div>
              <div class="col-md-3">
                <label class="form-label">Fecha de nacimiento</label>
                <input v-model="form.fechaNacimiento" type="date" class="form-control" />
              </div>
              <div class="col-md-3">
                <label class="form-label">Sexo</label>
                <select v-model="form.sexo" class="form-select">
                  <option value="">-</option>
                  <option value="M">Masculino</option>
                  <option value="F">Femenino</option>
                </select>
              </div>
              <div class="col-md-6">
                <label class="form-label">País de nacionalidad</label>
                <input v-model="form.paisNacionalidad" class="form-control" />
              </div>
              <div class="col-md-6">
                <label class="form-label">Dirección</label>
                <input v-model="form.direccion" class="form-control" />
              </div>
              <div class="col-md-3">
                <label class="form-label">Teléfono</label>
                <input v-model="form.telefono" class="form-control" />
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
import { onMounted, reactive, ref } from 'vue'
import { Modal } from 'bootstrap'
import api, { mensajeError } from '../../services/api'

const personas = ref([])
const cargando = ref(false)
const guardando = ref(false)
const busqueda = ref('')
const pagina = ref(1)
const totalPaginas = ref(0)
const totalElementos = ref(0)
const alerta = ref(null)

const personaVacia = () => ({
  id: null,
  tipoDocumento: 'CI',
  nroDocumento: '',
  apellidoPaterno: '',
  apellidoMaterno: '',
  apellidoCasada: '',
  nombres: '',
  fechaNacimiento: '',
  sexo: '',
  paisNacionalidad: 'Bolivia',
  direccion: '',
  telefono: ''
})

const form = reactive(personaVacia())

let modal = null

function mostrarAlerta(texto, tipo) {
  alerta.value = { texto, tipo }
  setTimeout(() => (alerta.value = null), 4000)
}

function nombreCompleto(per) {
  return [per.apellidoPaterno, per.apellidoMaterno, per.apellidoCasada, per.nombres]
    .filter(Boolean)
    .map((x) => x.trim())
    .join(' ') || per.nroDocumento
}

async function cargar(p) {
  if (p < 0) return
  cargando.value = true
  try {
    const { data } = await api.get('/personas', {
      params: { page: p, size: 10, q: busqueda.value || undefined }
    })
    personas.value = data.content
    pagina.value = data.number + 1
    totalPaginas.value = data.totalPages
    totalElementos.value = data.totalElements
  } catch (e) {
    mostrarAlerta(mensajeError(e), 'alert-danger')
  } finally {
    cargando.value = false
  }
}

function nuevo() {
  Object.assign(form, personaVacia())
  modal.show()
}

function editar(per) {
  Object.assign(form, per)
  modal.show()
}

async function guardar() {
  guardando.value = true
  try {
    if (form.id) {
      await api.put(`/personas/${form.id}`, form)
    } else {
      await api.post('/personas', form)
    }
    modal.hide()
    mostrarAlerta('Persona guardada correctamente', 'alert-success')
    cargar(pagina.value - 1)
  } catch (e) {
    mostrarAlerta(mensajeError(e), 'alert-danger')
  } finally {
    guardando.value = false
  }
}

async function eliminar(per) {
  if (!confirm(`¿Eliminar a ${nombreCompleto(per)}?`)) return
  try {
    await api.delete(`/personas/${per.id}`)
    mostrarAlerta('Persona eliminada', 'alert-success')
    cargar(pagina.value - 1)
  } catch (e) {
    mostrarAlerta(mensajeError(e), 'alert-danger')
  }
}

onMounted(() => {
  modal = new Modal(document.getElementById('modalPersona'))
  cargar(0)
})
</script>
