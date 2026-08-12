<template>
  <div>
    <div class="d-flex justify-content-between align-items-center mb-3">
      <h4 class="mb-0"><i class="bi bi-person-lines-fill me-2"></i>Descuentos por Empleado</h4>
    </div>

    <div v-if="alerta" class="alert" :class="alerta.tipo">{{ alerta.texto }}</div>

    <div class="card shadow-sm border-0 mb-3">
      <div class="card-body">
        <div class="row g-3 align-items-end">
          <div class="col-md-6">
            <label class="form-label">Empleado *</label>
            <select v-model="empleadoId" class="form-select" @change="cargarDescuentos">
              <option :value="null" disabled>-- Seleccionar empleado --</option>
              <option v-for="e in empleados" :key="e.id" :value="e.id">
                {{ nombreCompleto(e) }} - {{ e.persona.tipoDocumento }} {{ e.persona.nroDocumento }}
              </option>
            </select>
          </div>
          <div class="col-md-3 d-grid">
            <button class="btn btn-outline-secondary" @click="cargarDescuentos">
              <i class="bi bi-arrow-clockwise me-1"></i>Recargar
            </button>
          </div>
        </div>
        <p class="text-muted small mt-2 mb-0">
          Aquí se configuran los descuentos <strong>variables</strong> de cada empleado.
          Los descuentos <strong>fijos</strong> se aplican automáticamente a todos con el monto
          definido en la configuración de conceptos.
        </p>
      </div>
    </div>

    <div v-if="empleadoId" class="card shadow-sm border-0">
      <div class="card-body">
        <div class="table-responsive">
          <table class="table table-hover align-middle">
            <thead>
              <tr>
                <th>Código</th>
                <th>Descuento</th>
                <th style="width: 220px" class="text-end">Monto (Bs)</th>
              </tr>
            </thead>
            <tbody>
              <tr v-if="descuentos.length === 0">
                <td colspan="3" class="text-center text-muted py-4">
                  No hay descuentos variables configurados.
                </td>
              </tr>
              <tr v-for="d in descuentos" :key="d.conceptoId">
                <td><code>{{ d.codigo }}</code></td>
                <td>{{ d.nombre }}</td>
                <td>
                  <input v-model="d.monto" type="number" step="0.01" min="0" class="form-control text-end" />
                </td>
              </tr>
            </tbody>
            <tfoot v-if="descuentos.length > 0">
              <tr>
                <td colspan="2" class="text-end fw-bold">Total descuentos variables</td>
                <td class="text-end fw-bold">{{ fmtNumero(total) }}</td>
              </tr>
            </tfoot>
          </table>
        </div>
        <div class="d-flex justify-content-end">
          <button class="btn btn-primary" :disabled="guardando" @click="guardar">
            <span v-if="guardando" class="spinner-border spinner-border-sm me-1"></span>
            Guardar descuentos
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed, onMounted, ref } from 'vue'
import api, { mensajeError } from '../../services/api'

const empleados = ref([])
const empleadoId = ref(null)
const descuentos = ref([])
const guardando = ref(false)
const alerta = ref(null)

const total = computed(() =>
  descuentos.value.reduce((acc, d) => acc + (Number(d.monto) || 0), 0)
)

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
  if (v === null || v === undefined) return '0,00'
  return Number(v).toLocaleString('es-BO', { minimumFractionDigits: 2, maximumFractionDigits: 2 })
}

async function cargarEmpleados() {
  try {
    const { data } = await api.get('/empleados', { params: { page: 0, size: 1000 } })
    empleados.value = data.content
  } catch (e) {
    mostrarAlerta(mensajeError(e), 'alert-danger')
  }
}

async function cargarDescuentos() {
  descuentos.value = []
  if (!empleadoId.value) return
  try {
    const { data } = await api.get(`/empleados/${empleadoId.value}/descuentos`)
    descuentos.value = data.map((d) => ({ ...d, monto: Number(d.monto) }))
  } catch (e) {
    mostrarAlerta(mensajeError(e), 'alert-danger')
  }
}

async function guardar() {
  if (!empleadoId.value) return
  guardando.value = true
  try {
    const payload = descuentos.value.map((d) => ({
      conceptoId: d.conceptoId,
      monto: Number(d.monto) || 0
    }))
    await api.put(`/empleados/${empleadoId.value}/descuentos`, payload)
    mostrarAlerta('Descuentos guardados correctamente', 'alert-success')
  } catch (e) {
    mostrarAlerta(mensajeError(e), 'alert-danger')
  } finally {
    guardando.value = false
  }
}

onMounted(cargarEmpleados)
</script>
