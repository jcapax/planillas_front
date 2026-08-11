<template>
  <div>
    <h4 class="mb-4"><i class="bi bi-speedometer2 me-2"></i>Panel de Control</h4>

    <div class="row g-3">
      <div class="col-md-3 col-sm-6">
        <div class="card shadow-sm border-0">
          <div class="card-body text-center">
            <i class="bi bi-people display-5 text-primary"></i>
            <h2 class="mt-2 mb-0">{{ stats.empleados }}</h2>
            <p class="text-muted mb-0">Empleados Activos</p>
          </div>
        </div>
      </div>
      <div class="col-md-3 col-sm-6">
        <div class="card shadow-sm border-0">
          <div class="card-body text-center">
            <i class="bi bi-building display-5 text-success"></i>
            <h2 class="mt-2 mb-0">{{ stats.empresas }}</h2>
            <p class="text-muted mb-0">Empresas</p>
          </div>
        </div>
      </div>
      <div class="col-md-3 col-sm-6">
        <div class="card shadow-sm border-0">
          <div class="card-body text-center">
            <i class="bi bi-file-earmark-spreadsheet display-5 text-warning"></i>
            <h2 class="mt-2 mb-0">{{ stats.planillas }}</h2>
            <p class="text-muted mb-0">Planillas</p>
          </div>
        </div>
      </div>
      <div class="col-md-3 col-sm-6">
        <div class="card shadow-sm border-0">
          <div class="card-body text-center">
            <i class="bi bi-tags display-5 text-info"></i>
            <h2 class="mt-2 mb-0">{{ stats.conceptos }}</h2>
            <p class="text-muted mb-0">Conceptos</p>
          </div>
        </div>
      </div>
    </div>

    <div class="card mt-4 shadow-sm border-0">
      <div class="card-header">Sobre el sistema</div>
      <div class="card-body">
        <p>
          Sistema informático para el control de planillas salariales de la empresa
          <strong>Sucre Sureña</strong>, diseñado a partir del análisis de la hoja
          <em>"auxiliar"</em> de la planilla de haberes (Julio 2026).
        </p>
        <p class="mb-0">
          Para comenzar, complete la <router-link to="/configuracion/empresa">configuración básica</router-link>:
          datos de la empresa, registro de empleados, parámetros de aportes, tabla de bono de
          antigüedad y conceptos de haberes/descuentos.
        </p>
      </div>
    </div>
  </div>
</template>

<script setup>
import { onMounted, reactive } from 'vue'
import api, { mensajeError } from '../services/api'

const stats = reactive({ empleados: 0, empresas: 0, planillas: 0, conceptos: 0 })

onMounted(async () => {
  try {
    const [emp, emps, plan, conc] = await Promise.all([
      api.get('/empresas'),
      api.get('/empleados?size=1'),
      api.get('/planillas'),
      api.get('/conceptos')
    ])
    stats.empresas = emp.data.length
    stats.empleados = emps.data.totalElements
    stats.planillas = plan.data.length
    stats.conceptos = conc.data.length
  } catch (e) {
    console.error(mensajeError(e))
  }
})
</script>
