<template>
  <div>
    <div class="d-flex justify-content-between align-items-center mb-3">
      <h4 class="mb-0"><i class="bi bi-sliders me-2"></i>Parámetros del Sistema</h4>
      <button class="btn btn-primary" @click="nuevo">
        <i class="bi bi-plus-lg me-1"></i>Nuevo Parámetro
      </button>
    </div>

    <div v-if="alerta" class="alert" :class="alerta.tipo">{{ alerta.texto }}</div>

    <div class="card shadow-sm border-0">
      <div class="card-header">Parámetros</div>
      <div class="card-body">
        <div class="table-responsive">
          <table class="table table-hover align-middle">
            <thead>
              <tr>
                <th>Código</th>
                <th>Nombre</th>
                <th class="text-end">Valor</th>
                <th>Unidad</th>
                <th>Descripción</th>
                <th class="text-end">Acciones</th>
              </tr>
            </thead>
            <tbody>
              <tr v-if="parametros.length === 0">
                <td colspan="6" class="text-center text-muted py-4">Sin parámetros.</td>
              </tr>
              <tr v-for="p in parametros" :key="p.id">
                <td><code>{{ p.codigo }}</code></td>
                <td>{{ p.nombre }}</td>
                <td class="text-end">
                  <span v-if="p.unidad === 'PORCENTAJE'" class="badge bg-primary">
                    {{ (Number(p.valor) * 100).toFixed(2) }}%
                  </span>
                  <span v-else>{{ p.valor }}</span>
                </td>
                <td>{{ p.unidad }}</td>
                <td class="text-muted small">{{ p.descripcion }}</td>
                <td class="text-end">
                  <button class="btn btn-sm btn-outline-primary me-1" @click="editar(p)">
                    <i class="bi bi-pencil"></i>
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

    <div class="modal fade" id="modalParametro" tabindex="-1" data-bs-backdrop="static">
      <div class="modal-dialog">
        <div class="modal-content">
          <div class="modal-header">
            <h5 class="modal-title">{{ form.id ? 'Editar Parámetro' : 'Nuevo Parámetro' }}</h5>
            <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
          </div>
          <div class="modal-body">
            <div class="mb-3">
              <label class="form-label">Código *</label>
              <input v-model="form.codigo" class="form-control" :readonly="!!form.id" required />
            </div>
            <div class="mb-3">
              <label class="form-label">Nombre *</label>
              <input v-model="form.nombre" class="form-control" required />
            </div>
            <div class="row g-3 mb-3">
              <div class="col-md-6">
                <label class="form-label">Valor *</label>
                <input v-model="form.valor" type="number" step="0.000001" class="form-control" required />
              </div>
              <div class="col-md-6">
                <label class="form-label">Unidad</label>
                <select v-model="form.unidad" class="form-select">
                  <option value="PORCENTAJE">PORCENTAJE</option>
                  <option value="HORAS">HORAS</option>
                  <option value="DIAS">DIAS</option>
                  <option value="MONTO">MONTO</option>
                </select>
              </div>
            </div>
            <div class="mb-3">
              <label class="form-label">Descripción</label>
              <textarea v-model="form.descripcion" class="form-control" rows="2"></textarea>
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

const parametros = ref([])
const guardando = ref(false)
const alerta = ref(null)

const form = reactive({
  id: null,
  codigo: '',
  nombre: '',
  valor: 0,
  unidad: 'PORCENTAJE',
  descripcion: ''
})

let modal = null

function mostrarAlerta(texto, tipo) {
  alerta.value = { texto, tipo }
  setTimeout(() => (alerta.value = null), 4000)
}

async function cargar() {
  try {
    const { data } = await api.get('/parametros')
    parametros.value = data
  } catch (e) {
    mostrarAlerta(mensajeError(e), 'alert-danger')
  }
}

function nuevo() {
  Object.assign(form, {
    id: null, codigo: '', nombre: '', valor: 0, unidad: 'PORCENTAJE', descripcion: ''
  })
  modal.show()
}

function editar(p) {
  Object.assign(form, p)
  modal.show()
}

async function guardar() {
  guardando.value = true
  try {
    if (form.id) {
      await api.put(`/parametros/${form.id}`, form)
    } else {
      await api.post('/parametros', form)
    }
    modal.hide()
    mostrarAlerta('Parámetro guardado', 'alert-success')
    cargar()
  } catch (e) {
    mostrarAlerta(mensajeError(e), 'alert-danger')
  } finally {
    guardando.value = false
  }
}

async function eliminar(p) {
  if (!confirm(`¿Eliminar el parámetro ${p.codigo}?`)) return
  try {
    await api.delete(`/parametros/${p.id}`)
    mostrarAlerta('Parámetro eliminado', 'alert-success')
    cargar()
  } catch (e) {
    mostrarAlerta(mensajeError(e), 'alert-danger')
  }
}

onMounted(() => {
  modal = new Modal(document.getElementById('modalParametro'))
  cargar()
})
</script>
