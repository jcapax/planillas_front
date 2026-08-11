<template>
  <div>
    <div class="d-flex justify-content-between align-items-center mb-3">
      <h4 class="mb-0"><i class="bi bi-tags me-2"></i>Conceptos de Haberes, Aportes y Descuentos</h4>
      <button class="btn btn-primary" @click="nuevo">
        <i class="bi bi-plus-lg me-1"></i>Nuevo Concepto
      </button>
    </div>

    <div v-if="alerta" class="alert" :class="alerta.tipo">{{ alerta.texto }}</div>

    <ul class="nav nav-tabs mb-3">
      <li class="nav-item">
        <button class="nav-link" :class="{ active: tipoFiltro === 'HABER' }" @click="cambiarTipo('HABER')">
          Haberes
        </button>
      </li>
      <li class="nav-item">
        <button class="nav-link" :class="{ active: tipoFiltro === 'APORTE' }" @click="cambiarTipo('APORTE')">
          Aportes
        </button>
      </li>
      <li class="nav-item">
        <button class="nav-link" :class="{ active: tipoFiltro === 'DESCUENTO' }" @click="cambiarTipo('DESCUENTO')">
          Descuentos
        </button>
      </li>
      <li class="nav-item">
        <button class="nav-link" :class="{ active: tipoFiltro === '' }" @click="cambiarTipo('')">
          Todos
        </button>
      </li>
    </ul>

    <div class="card shadow-sm border-0">
      <div class="card-body">
        <div class="table-responsive">
          <table class="table table-hover align-middle">
            <thead>
              <tr>
                <th>Código</th>
                <th>Nombre</th>
                <th>Tipo</th>
                <th>% Aplica</th>
                <th class="text-end">Orden</th>
                <th class="text-end">Acciones</th>
              </tr>
            </thead>
            <tbody>
              <tr v-if="conceptos.length === 0">
                <td colspan="6" class="text-center text-muted py-4">Sin conceptos.</td>
              </tr>
              <tr v-for="c in conceptos" :key="c.id">
                <td><code>{{ c.codigo }}</code></td>
                <td>{{ c.nombre }}</td>
                <td>
                  <span class="badge" :class="badgeTipo(c.tipo)">{{ c.tipo }}</span>
                </td>
                <td>
                  <span v-if="c.aplicaPorcentaje" class="badge bg-primary">
                    {{ (Number(c.porcentaje) * 100).toFixed(2) }}%
                  </span>
                  <span v-else class="text-muted">No</span>
                </td>
                <td class="text-end">{{ c.orden }}</td>
                <td class="text-end">
                  <button class="btn btn-sm btn-outline-primary me-1" @click="editar(c)">
                    <i class="bi bi-pencil"></i>
                  </button>
                  <button class="btn btn-sm btn-outline-danger" @click="eliminar(c)">
                    <i class="bi bi-trash"></i>
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>

    <div class="modal fade" id="modalConcepto" tabindex="-1" data-bs-backdrop="static">
      <div class="modal-dialog">
        <div class="modal-content">
          <div class="modal-header">
            <h5 class="modal-title">{{ form.id ? 'Editar Concepto' : 'Nuevo Concepto' }}</h5>
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
                <label class="form-label">Tipo *</label>
                <select v-model="form.tipo" class="form-select">
                  <option value="HABER">HABER</option>
                  <option value="APORTE">APORTE</option>
                  <option value="DESCUENTO">DESCUENTO</option>
                </select>
              </div>
              <div class="col-md-6">
                <label class="form-label">Orden</label>
                <input v-model="form.orden" type="number" class="form-control" />
              </div>
              <div class="col-md-6">
                <label class="form-label">Aplica porcentaje</label>
                <select v-model="form.aplicaPorcentaje" class="form-select">
                  <option :value="false">No</option>
                  <option :value="true">Sí</option>
                </select>
              </div>
              <div class="col-md-6">
                <label class="form-label">Porcentaje</label>
                <input
                  v-model="form.porcentaje"
                  type="number"
                  step="0.0001"
                  class="form-control"
                  :disabled="!form.aplicaPorcentaje"
                />
              </div>
            </div>
            <p class="text-muted small mb-0">
              El porcentaje se almacena en forma decimal. Ej.: 10% se guarda como 0.10.
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

const conceptos = ref([])
const tipoFiltro = ref('HABER')
const guardando = ref(false)
const alerta = ref(null)

const form = reactive({
  id: null,
  codigo: '',
  nombre: '',
  tipo: 'HABER',
  aplicaPorcentaje: false,
  porcentaje: null,
  orden: 0
})

let modal = null

function mostrarAlerta(texto, tipo) {
  alerta.value = { texto, tipo }
  setTimeout(() => (alerta.value = null), 4000)
}

function badgeTipo(tipo) {
  return {
    HABER: 'bg-success',
    APORTE: 'bg-info text-dark',
    DESCUENTO: 'bg-warning text-dark'
  }[tipo] || 'bg-secondary'
}

async function cargar() {
  try {
    const { data } = await api.get('/conceptos', {
      params: { tipo: tipoFiltro.value || undefined }
    })
    conceptos.value = data
  } catch (e) {
    mostrarAlerta(mensajeError(e), 'alert-danger')
  }
}

function cambiarTipo(tipo) {
  tipoFiltro.value = tipo
  cargar()
}

function nuevo() {
  Object.assign(form, {
    id: null, codigo: '', nombre: '', tipo: tipoFiltro.value || 'HABER',
    aplicaPorcentaje: false, porcentaje: null, orden: 0
  })
  modal.show()
}

function editar(c) {
  Object.assign(form, c)
  modal.show()
}

async function guardar() {
  guardando.value = true
  try {
    const payload = { ...form }
    if (payload.aplicaPorcentaje) {
      payload.porcentaje = Number(payload.porcentaje) / 100
    } else {
      payload.porcentaje = null
    }
    if (form.id) {
      await api.put(`/conceptos/${form.id}`, payload)
    } else {
      await api.post('/conceptos', payload)
    }
    modal.hide()
    mostrarAlerta('Concepto guardado', 'alert-success')
    cargar()
  } catch (e) {
    mostrarAlerta(mensajeError(e), 'alert-danger')
  } finally {
    guardando.value = false
  }
}

async function eliminar(c) {
  if (!confirm(`¿Eliminar el concepto ${c.codigo}?`)) return
  try {
    await api.delete(`/conceptos/${c.id}`)
    mostrarAlerta('Concepto eliminado', 'alert-success')
    cargar()
  } catch (e) {
    mostrarAlerta(mensajeError(e), 'alert-danger')
  }
}

onMounted(() => {
  modal = new Modal(document.getElementById('modalConcepto'))
  cargar()
})
</script>
