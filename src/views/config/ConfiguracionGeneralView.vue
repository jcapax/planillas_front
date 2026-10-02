<template>
  <div>
    <div class="d-flex justify-content-between align-items-center mb-3">
      <h4 class="mb-0"><i class="bi bi-gear me-2"></i>Configuración general</h4>
      <button class="btn btn-primary" @click="guardar">
        <i class="bi bi-save me-1"></i>Guardar
      </button>
    </div>

    <div v-if="alerta" class="alert" :class="alerta.tipo">{{ alerta.texto }}</div>

    <div class="card shadow-sm border-0">
      <div class="card-header">Bono de antigüedad</div>
      <div class="card-body">
        <div class="row g-3">
          <div class="col-md-6">
            <label class="form-label">Mínimo nacional (Bs)</label>
            <input v-model.number="form.minimoNacional" type="number" step="0.01" min="0" class="form-control" />
          </div>
          <div class="col-md-6">
            <label class="form-label">Cantidad de mínimos</label>
            <input v-model.number="form.cantidadMinimoNacional" type="number" step="0.01" min="0.01" class="form-control" />
          </div>
        </div>
      </div>
    </div>

    <div class="card shadow-sm border-0 mt-3">
      <div class="card-header">Riesgo común por edad</div>
      <div class="card-body">
        <div class="row g-3">
          <div class="col-md-6">
            <label class="form-label">Edad a partir de la cual aplica el porcentaje especial</label>
            <input v-model.number="form.edadRiesgoComun" type="number" step="1" min="0" class="form-control" />
          </div>
          <div class="col-md-6">
            <label class="form-label">Porcentaje de riesgo común para esa edad</label>
            <input v-model.number="form.edadRiesgoComunPct" type="number" step="0.0001" min="0" class="form-control" />
          </div>
          <div class="col-12">
            <small class="text-muted">
              Si un empleado tiene una edad igual o superior a la indicada, el concepto AFP_2_21 se calcula con este porcentaje en lugar de la tasa normal de riesgo común.
            </small>
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
  minimoNacional: 0,
  cantidadMinimoNacional: 1,
  edadRiesgoComun: null,
  edadRiesgoComunPct: null
})

const alerta = ref(null)

function mostrarAlerta(texto, tipo) {
  alerta.value = { texto, tipo }
  setTimeout(() => (alerta.value = null), 4000)
}

onMounted(async () => {
  try {
    const { data } = await api.get('/configuracion')
    Object.assign(form, data)
  } catch (e) {
    mostrarAlerta(mensajeError(e), 'alert-danger')
  }
})

async function guardar() {
  try {
    const { data } = await api.put('/configuracion', form)
    Object.assign(form, data)
    mostrarAlerta('Configuración guardada correctamente', 'alert-success')
  } catch (e) {
    mostrarAlerta(mensajeError(e), 'alert-danger')
  }
}
</script>
