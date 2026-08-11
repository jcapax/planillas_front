<template>
  <div>
    <div class="d-flex justify-content-between align-items-center mb-3">
      <h4 class="mb-0"><i class="bi bi-building me-2"></i>Empresa</h4>
      <button class="btn btn-primary" @click="guardar">
        <i class="bi bi-save me-1"></i>Guardar
      </button>
    </div>

    <div v-if="alerta" class="alert" :class="alerta.tipo">{{ alerta.texto }}</div>

    <div class="card shadow-sm border-0">
      <div class="card-header">Datos generales</div>
      <div class="card-body">
        <div class="row g-3">
          <div class="col-md-8">
            <label class="form-label">Razón social *</label>
            <input v-model="form.nombre" class="form-control" required />
          </div>
          <div class="col-md-4">
            <label class="form-label">NIT</label>
            <input v-model="form.nit" class="form-control" />
          </div>
          <div class="col-md-4">
            <label class="form-label">CNSS</label>
            <input v-model="form.cnss" class="form-control" />
          </div>
          <div class="col-md-4">
            <label class="form-label">Ciudad</label>
            <input v-model="form.ciudad" class="form-control" />
          </div>
          <div class="col-md-4">
            <label class="form-label">Teléfono</label>
            <input v-model="form.telefono" class="form-control" />
          </div>
          <div class="col-md-6">
            <label class="form-label">Zona</label>
            <input v-model="form.zona" class="form-control" />
          </div>
          <div class="col-md-6">
            <label class="form-label">Calle / Dirección</label>
            <input v-model="form.calle" class="form-control" />
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { onMounted, reactive, ref } from 'vue'
import api, { mensajeError } from '../../services/api'

const form = reactive({
  id: null,
  nombre: 'Sucre Sureña - Sociedad Industrial del Sur S.A.',
  nit: '',
  cnss: '',
  zona: '',
  calle: '',
  ciudad: '',
  telefono: ''
})

const alerta = ref(null)

function mostrarAlerta(texto, tipo) {
  alerta.value = { texto, tipo }
  setTimeout(() => (alerta.value = null), 4000)
}

onMounted(async () => {
  try {
    const { data } = await api.get('/empresas')
    if (data.length > 0) {
      Object.assign(form, data[0])
    }
  } catch (e) {
    mostrarAlerta(mensajeError(e), 'alert-danger')
  }
})

async function guardar() {
  try {
    if (form.id) {
      await api.put(`/empresas/${form.id}`, form)
    } else {
      const { data } = await api.post('/empresas', form)
      form.id = data.id
    }
    mostrarAlerta('Empresa guardada correctamente', 'alert-success')
  } catch (e) {
    mostrarAlerta(mensajeError(e), 'alert-danger')
  }
}
</script>
