<template>
  <div>
    <div class="d-flex justify-content-between align-items-center mb-3">
      <h4 class="mb-0"><i class="bi bi-person-lines-fill me-2"></i>Ingresos y Descuentos por Empleado</h4>
      <div class="btn-group" role="group">
        <button class="btn btn-sm" :class="modo === 'individual' ? 'btn-primary' : 'btn-outline-primary'" @click="modo = 'individual'">
          <i class="bi bi-person me-1"></i>Individual
        </button>
        <button class="btn btn-sm" :class="modo === 'matriz' ? 'btn-primary' : 'btn-outline-primary'" @click="cambiarAMatriz">
          <i class="bi bi-table me-1"></i>Matriz Excel
        </button>
      </div>
    </div>

    <div v-if="alerta" class="alert" :class="alerta.tipo">{{ alerta.texto }}</div>

    <div class="card shadow-sm border-0 mb-3">
      <div class="card-body py-2">
        <div class="row g-2 align-items-end">
          <div class="col-md-4">
            <label class="form-label">Tipo de concepto</label>
            <select v-model="filtroTipos" class="form-select" @change="cambiarFiltroTipos">
              <option value="">Todos (ingresos y descuentos)</option>
              <option value="HABER">Ingresos (HABER)</option>
              <option value="DESCUENTO">Descuentos (DESCUENTO)</option>
              <option value="APORTE">Aportes (APORTE)</option>
            </select>
          </div>
          <div class="col-md-8">
            <p class="text-muted small mb-0">
              La matriz despliega <strong>todos los empleados a la vez</strong> con los tipos de
              ingreso o descuento en columnas paralelas. Los descuentos
              <strong>fijos</strong> y los conceptos calculados por el sistema (haber básico,
              bono, dominical, AFP) se aplican automáticamente y no aparecen aquí.
            </p>
          </div>
        </div>
      </div>
    </div>

    <!-- Modo individual (existente) -->
    <div v-if="modo === 'individual'">
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
            Aquí se configuran los ingresos y descuentos <strong>variables</strong> de cada empleado.
            Los descuentos <strong>fijos</strong> se aplican automáticamente a todos con el monto
            definido en la configuración de conceptos. Para editar varios empleados a la vez use la
            vista <strong>Matriz Excel</strong>.
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
                  <th>Concepto</th>
                  <th>Tipo</th>
                  <th style="width: 220px" class="text-end">Monto (Bs)</th>
                </tr>
              </thead>
              <tbody>
                <tr v-if="descuentos.length === 0">
                  <td colspan="4" class="text-center text-muted py-4">
                    No hay conceptos configurados para este filtro.
                  </td>
                </tr>
                <tr v-for="d in descuentos" :key="d.conceptoId">
                  <td><code>{{ d.codigo }}</code></td>
                  <td>{{ d.nombre }}</td>
                  <td><span class="badge" :class="badgeTipo(d.tipo)">{{ d.tipo }}</span></td>
                  <td>
                    <input v-model="d.monto" type="number" step="0.01" min="0" class="form-control text-end" />
                  </td>
                </tr>
              </tbody>
              <tfoot v-if="descuentos.length > 0">
                <tr>
                  <td colspan="3" class="text-end fw-bold">Total</td>
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

    <!-- Modo matriz estilo Excel -->
    <div v-else class="card shadow-sm border-0">
      <div class="card-body">
        <p class="text-muted small mb-2">
          Todos los empleados en filas y los tipos de descuento en columnas paralelas, como una
          tabla Excel. Estos valores se usan al <strong>generar</strong> cada planilla.
        </p>
        <div class="row g-2 align-items-center mb-2">
          <div class="col-md-4">
            <div class="input-group input-group-sm">
              <span class="input-group-text"><i class="bi bi-search"></i></span>
              <input v-model="matrizFiltro" type="text" class="form-control" placeholder="Filtrar empleado..." />
            </div>
          </div>
          <div class="col-md-8 text-md-end">
            <button class="btn btn-sm btn-outline-secondary me-2" @click="cargarMatriz">
              <i class="bi bi-arrow-clockwise me-1"></i>Recargar
            </button>
            <button class="btn btn-sm btn-primary" :disabled="guardandoMatriz || matrizConceptos.length === 0" @click="guardarMatriz">
              <span v-if="guardandoMatriz" class="spinner-border spinner-border-sm me-1"></span>
              <i v-else class="bi bi-save me-1"></i>Guardar todo
            </button>
          </div>
        </div>
        <div class="text-muted small mb-2">
          <span v-if="matrizCargando" class="spinner-border spinner-border-sm me-2"></span>
          {{ matrizFilasFiltradas.length }} empleados
          · {{ matrizConceptos.length }} conceptos
          · Haberes: <strong>{{ fmtNumero(matrizTotalGrupo('HABER')) }}</strong>
          · Descuentos: <strong>{{ fmtNumero(matrizTotalGrupo('DESCUENTO')) }}</strong>
          <span v-if="tieneAportes">· Aportes: <strong>{{ fmtNumero(matrizTotalGrupo('APORTE')) }}</strong></span>
        </div>
        <div v-if="matrizConceptos.length === 0 && !matrizCargando" class="alert alert-warning">
          No hay conceptos para este filtro. Créelos en Configuración → Conceptos.
        </div>
        <div class="table-responsive matriz-excel">
          <table class="table table-sm table-bordered table-hover align-middle mb-0">
            <thead class="table-light">
              <tr>
                <th class="sticky-emp bg-light" style="min-width: 240px">Empleado</th>
                <th v-for="c in matrizConceptos" :key="c.id" class="text-center" style="min-width: 140px">
                  <div><span class="badge" :class="badgeTipo(c.tipo)">{{ c.tipo }}</span></div>
                  <div class="fw-bold">{{ c.codigo }}</div>
                  <div class="fw-normal text-muted excel-nombre">{{ c.nombre }}</div>
                </th>
                <th v-if="tieneHaberes" class="text-end bg-light" style="min-width: 110px">Haberes</th>
                <th v-if="tieneDescuentos" class="text-end bg-light" style="min-width: 110px">Dctos.</th>
                <th v-if="tieneAportes" class="text-end bg-light" style="min-width: 110px">Aportes</th>
                <th class="text-end bg-light" style="min-width: 120px">Neto fila</th>
              </tr>
            </thead>
            <tbody>
              <tr v-if="matrizFilasFiltradas.length === 0">
                <td :colspan="matrizConceptos.length + 5" class="text-center text-muted py-4">
                  {{ matrizCargando ? 'Cargando...' : 'Sin empleados.' }}
                </td>
              </tr>
              <tr v-for="f in matrizFilasFiltradas" :key="f.empleadoId">
                <td class="sticky-emp">
                  <div class="fw-semibold">{{ f.nombre }}</div>
                  <div class="text-muted small">{{ f.documento }}</div>
                </td>
                <td v-for="c in matrizConceptos" :key="c.id" class="p-1">
                  <input
                    v-model.number="f.montos[c.id]"
                    type="number"
                    step="0.01"
                    min="0"
                    class="form-control form-control-sm text-end excel-cell"
                    @focus="$event.target.select()"
                  />
                </td>
                <td v-if="tieneHaberes" class="text-end text-success fw-semibold">{{ fmtNumero(subtotalFila(f, 'HABER')) }}</td>
                <td v-if="tieneDescuentos" class="text-end text-danger fw-semibold">{{ fmtNumero(subtotalFila(f, 'DESCUENTO')) }}</td>
                <td v-if="tieneAportes" class="text-end text-info fw-semibold">{{ fmtNumero(subtotalFila(f, 'APORTE')) }}</td>
                <td class="text-end fw-bold">{{ fmtNumero(netoFila(f)) }}</td>
              </tr>
            </tbody>
            <tfoot v-if="matrizFilasFiltradas.length > 0" class="table-light">
              <tr>
                <td class="text-end fw-bold sticky-emp">Total columna</td>
                <td v-for="c in matrizConceptos" :key="c.id" class="text-end fw-bold">
                  {{ fmtNumero(columnaTotalMatriz(c.id)) }}
                </td>
                <td v-if="tieneHaberes" class="text-end fw-bold text-success">{{ fmtNumero(matrizTotalGrupo('HABER')) }}</td>
                <td v-if="tieneDescuentos" class="text-end fw-bold text-danger">{{ fmtNumero(matrizTotalGrupo('DESCUENTO')) }}</td>
                <td v-if="tieneAportes" class="text-end fw-bold text-info">{{ fmtNumero(matrizTotalGrupo('APORTE')) }}</td>
                <td class="text-end fw-bold">{{ fmtNumero(matrizNetoTotal) }}</td>
              </tr>
            </tfoot>
          </table>
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
const modo = ref('individual')

// --- Matriz Excel ---
const matrizConceptos = ref([])
const matrizFilas = ref([])
const matrizFiltro = ref('')
const matrizCargando = ref(false)
const guardandoMatriz = ref(false)
const filtroTipos = ref('')

const total = computed(() =>
  descuentos.value.reduce((acc, d) => acc + (Number(d.monto) || 0), 0)
)

function badgeTipo(tipo) {
  return {
    HABER: 'bg-success',
    APORTE: 'bg-info text-dark',
    DESCUENTO: 'bg-warning text-dark'
  }[tipo] || 'bg-secondary'
}

const tieneHaberes = computed(() => matrizConceptos.value.some((c) => c.tipo === 'HABER'))
const tieneDescuentos = computed(() => matrizConceptos.value.some((c) => c.tipo === 'DESCUENTO'))
const tieneAportes = computed(() => matrizConceptos.value.some((c) => c.tipo === 'APORTE'))

const matrizFilasFiltradas = computed(() => {
  const q = matrizFiltro.value.trim().toLowerCase()
  if (!q) return matrizFilas.value
  return matrizFilas.value.filter((f) =>
    (f.nombre || '').toLowerCase().includes(q) ||
    (f.documento || '').toLowerCase().includes(q)
  )
})

const matrizGranTotal = computed(() =>
  matrizFilas.value.reduce((acc, f) => acc + filaTotalMatriz(f), 0)
)

const matrizGranTotalFiltrado = computed(() =>
  matrizFilasFiltradas.value.reduce((acc, f) => acc + filaTotalMatriz(f), 0)
)

const matrizNetoTotal = computed(() =>
  matrizTotalGrupo('HABER') - matrizTotalGrupo('DESCUENTO') - matrizTotalGrupo('APORTE')
)

function filaTotalMatriz(f) {
  return matrizConceptos.value.reduce((acc, c) => acc + (Number(f.montos[c.id]) || 0), 0)
}

function subtotalFila(f, tipo) {
  return matrizConceptos.value
    .filter((c) => c.tipo === tipo)
    .reduce((acc, c) => acc + (Number(f.montos[c.id]) || 0), 0)
}

function netoFila(f) {
  return subtotalFila(f, 'HABER') - subtotalFila(f, 'DESCUENTO') - subtotalFila(f, 'APORTE')
}

function matrizTotalGrupo(tipo) {
  const ids = new Set(matrizConceptos.value.filter((c) => c.tipo === tipo).map((c) => c.id))
  return matrizFilasFiltradas.value.reduce(
    (acc, f) => acc + Object.entries(f.montos || {})
      .reduce((a, [k, v]) => a + (ids.has(Number(k)) ? Number(v) || 0 : 0), 0),
    0
  )
}

function columnaTotalMatriz(conceptoId) {
  return matrizFilasFiltradas.value.reduce((acc, f) => acc + (Number(f.montos[conceptoId]) || 0), 0)
}

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
    const { data } = await api.get(`/empleados/${empleadoId.value}/descuentos`, {
      params: { tipos: filtroTipos.value || undefined }
    })
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

function cambiarAMatriz() {
  modo.value = 'matriz'
  if (matrizFilas.value.length === 0) cargarMatriz()
}

function cambiarFiltroTipos() {
  if (modo.value === 'matriz') {
    cargarMatriz()
  } else if (empleadoId.value) {
    cargarDescuentos()
  }
}

async function cargarMatriz() {
  matrizCargando.value = true
  try {
    const { data } = await api.get('/empleados/descuentos-matriz', {
      params: { tipos: filtroTipos.value || undefined }
    })
    matrizConceptos.value = data.conceptos || []
    matrizFilas.value = (data.filas || []).map((f) => {
      const montos = {}
      for (const [k, v] of Object.entries(f.montos || {})) {
        montos[k] = Number(v) || 0
      }
      return { ...f, montos }
    })
  } catch (e) {
    mostrarAlerta(mensajeError(e), 'alert-danger')
  } finally {
    matrizCargando.value = false
  }
}

async function guardarMatriz() {
  guardandoMatriz.value = true
  try {
    const payload = []
    for (const f of matrizFilas.value) {
      for (const c of matrizConceptos.value) {
        payload.push({
          empleadoId: f.empleadoId,
          conceptoId: c.id,
          monto: Number(f.montos[c.id]) || 0
        })
      }
    }
    await api.put('/empleados/descuentos-matriz', payload)
    mostrarAlerta('Conceptos masivos guardados correctamente', 'alert-success')
  } catch (e) {
    mostrarAlerta(mensajeError(e), 'alert-danger')
  } finally {
    guardandoMatriz.value = false
  }
}

onMounted(cargarEmpleados)
</script>

<style scoped>
.matriz-excel {
  max-height: 60vh;
}
.matriz-excel thead th {
  position: sticky;
  top: 0;
  z-index: 3;
}
.excel-cell {
  min-width: 110px;
}
.excel-cell:focus {
  border-color: #0d6efd;
  box-shadow: 0 0 0 0.15rem rgba(13, 110, 253, 0.25);
}
.excel-nombre {
  font-size: 0.72rem;
  max-width: 160px;
  white-space: normal;
}
.sticky-emp {
  position: sticky;
  left: 0;
  z-index: 2;
  background: #fff;
}
thead .sticky-emp {
  z-index: 4;
}
</style>
