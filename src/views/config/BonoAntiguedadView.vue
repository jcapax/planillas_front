<template>
  <div>
    <div class="d-flex justify-content-between align-items-center mb-3">
      <h4 class="mb-0"><i class="bi bi-graph-up me-2"></i>Tabla de Bono de Antigüedad</h4>
      <button class="btn btn-primary" @click="nuevo">
        <i class="bi bi-plus-lg me-1"></i>Nuevo Rango
      </button>
    </div>

    <div v-if="alerta" class="alert" :class="alerta.tipo">{{ alerta.texto }}</div>

    <div class="card shadow-sm border-0">
      <div class="card-header">
        Factores de antigüedad (hoja "FactorAntiguedad" de la planilla)
      </div>
      <div class="card-body">
        <div class="table-responsive">
          <table class="table table-hover align-middle">
            <thead>
              <tr>
                <th>Desde (años)</th>
                <th>Hasta (años)</th>
                <th>Desde (días)</th>
                <th>Hasta (días)</th>
                <th class="text-end">Porcentaje</th>
                <th>Descripción</th>
                <th class="text-end">Acciones</th>
              </tr>
            </thead>
            <tbody>
              <tr v-if="registros.length === 0">
                <td colspan="7" class="text-center text-muted py-4">Sin registros.</td>
              </tr>
              <tr v-for="b in registros" :key="b.id">
                <td>{{ b.desdeAnios ?? '-' }}</td>
                <td>{{ b.hastaAnios ?? 'adelante' }}</td>
                <td>{{ b.desdeDias ?? '-' }}</td>
                <td>{{ b.hastaDias ?? 'adelante' }}</td>
                <td class="text-end">
                  <span class="badge bg-primary">{{ (Number(b.porcentaje) * 100).toFixed(2) }}%</span>
                </td>
                <td>{{ b.descripcion || '-' }}</td>
                <td class="text-end">
                  <button class="btn btn-sm btn-outline-primary me-1" @click="editar(b)">
                    <i class="bi bi-pencil"></i>
                  </button>
                  <button class="btn btn-sm btn-outline-danger" @click="eliminar(b)">
                    <i class="bi bi-trash"></i>
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>

    <div class="modal fade" id="modalBono" tabindex="-1" data-bs-backdrop="static">
      <div class="modal-dialog">
        <div class="modal-content">
          <div class="modal-header">
            <h5 class="modal-title">{{ form.id ? 'Editar Rango' : 'Nuevo Rango' }}</h5>
            <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
          </div>
          <div class="modal-body">
            <div class="row g-3 mb-3">
              <div class="col-6">
                <label class="form-label">Desde (años)</label>
                <input v-model="form.desdeAnios" type="number" min="0" class="form-control" />
              </div>
              <div class="col-6">
                <label class="form-label">Hasta (años)</label>
                <input v-model="form.hastaAnios" type="number" min="0" class="form-control" />
              </div>
              <div class="col-6">
                <label class="form-label">Desde (días)</label>
                <input v-model="form.desdeDias" type="number" min="0" class="form-control" />
              </div>
              <div class="col-6">
                <label class="form-label">Hasta (días)</label>
                <input v-model="form.hastaDias" type="number" min="0" class="form-control" />
              </div>
              <div class="col-6">
                <label class="form-label">Porcentaje (%) *</label>
                <input v-model="form.porcentaje" type="number" step="0.01" min="0" max="100" class="form-control" required />
              </div>
              <div class="col-6">
                <label class="form-label">Descripción</label>
                <input v-model="form.descripcion" class="form-control" />
              </div>
            </div>
            <p class="text-muted small mb-0">
              El porcentaje se almacena en forma decimal. Ej.: 42% se guarda como 0.42.
            </p>
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

const registros = ref([])
const guardando = ref(false)
const alerta = ref(null)

const form = reactive({
  id: null,
  desdeAnios: null,
  hastaAnios: null,
  desdeDias: null,
  hastaDias: null,
  porcentaje: 0,
  descripcion: ''
})

let modal = null

function mostrarAlerta(texto, tipo) {
  alerta.value = { texto, tipo }
  setTimeout(() => (alerta.value = null), 4000)
}

async function cargar() {
  try {
    const { data } = await api.get('/bonos-antiguedad')
    registros.value = data
  } catch (e) {
    mostrarAlerta(mensajeError(e), 'alert-danger')
  }
}

function nuevo() {
  Object.assign(form, {
    id: null, desdeAnios: null, hastaAnios: null,
    desdeDias: null, hastaDias: null, porcentaje: 0, descripcion: ''
  })
  modal.show()
}

function editar(b) {
  Object.assign(form, b)
  modal.show()
}

async function guardar() {
  guardando.value = true
  try {
    const payload = { ...form, porcentaje: Number(form.porcentaje) / 100 }
    if (form.id) {
      await api.put(`/bonos-antiguedad/${form.id}`, payload)
    } else {
      await api.post('/bonos-antiguedad', payload)
    }
    modal.hide()
    mostrarAlerta('Rango guardado', 'alert-success')
    cargar()
  } catch (e) {
    mostrarAlerta(mensajeError(e), 'alert-danger')
  } finally {
    guardando.value = false
  }
}

async function eliminar(b) {
  if (!confirm(`¿Eliminar el rango "${b.descripcion || b.desdeDias}"?`)) return
  try {
    await api.delete(`/bonos-antiguedad/${b.id}`)
    mostrarAlerta('Rango eliminado', 'alert-success')
    cargar()
  } catch (e) {
    mostrarAlerta(mensajeError(e), 'alert-danger')
  }
}

onMounted(() => {
  modal = new Modal(document.getElementById('modalBono'))
  cargar()
})
</script>
