<template>
  <div>
    <nav class="navbar navbar-dark ss-navbar px-3">
      <span class="navbar-brand d-flex align-items-center gap-2 mb-0">
        <i class="bi bi-clipboard2-pulse"></i>
        <span class="fw-bold">Sucre Sureña</span>
        <span class="badge bg-warning text-dark ms-1">Planillas</span>
      </span>
      <div class="d-flex align-items-center gap-3">
        <span class="text-white-50 small d-none d-md-inline">
          <i class="bi bi-person-circle me-1"></i>{{ auth.nombre }} ({{ auth.rol }})
        </span>
        <button class="btn btn-outline-light btn-sm" @click="cerrarSesion">
          <i class="bi bi-box-arrow-right me-1"></i>Salir
        </button>
      </div>
    </nav>

    <div class="d-flex">
      <div class="sidebar p-3 d-none d-md-block" style="width: 250px">
        <ul class="nav flex-column">
          <li class="nav-item">
            <router-link class="nav-link" :class="{ active: ruta === 'dashboard' }" to="/dashboard">
              <i class="bi bi-speedometer2"></i>Inicio
            </router-link>
          </li>
          <li class="nav-item mt-3">
            <span class="text-uppercase text-white-50 small px-2">Configuración</span>
          </li>
          <li class="nav-item">
            <router-link class="nav-link" :class="{ active: ruta === 'empresa' }" to="/configuracion/empresa">
              <i class="bi bi-building"></i>Empresa
            </router-link>
          </li>
          <li class="nav-item">
            <router-link class="nav-link" :class="{ active: ruta === 'personas' }" to="/configuracion/personas">
              <i class="bi bi-person-vcard"></i>Personas
            </router-link>
          </li>
          <li class="nav-item">
            <router-link class="nav-link" :class="{ active: ruta === 'empleados' }" to="/configuracion/empleados">
              <i class="bi bi-people"></i>Empleados
            </router-link>
          </li>
          <li class="nav-item">
            <router-link class="nav-link" :class="{ active: ruta === 'parametros' }" to="/configuracion/parametros">
              <i class="bi bi-sliders"></i>Parámetros
            </router-link>
          </li>
          <li class="nav-item">
            <router-link class="nav-link" :class="{ active: ruta === 'bono-antiguedad' }" to="/configuracion/bono-antiguedad">
              <i class="bi bi-graph-up"></i>Bono Antigüedad
            </router-link>
          </li>
          <li class="nav-item">
            <router-link class="nav-link" :class="{ active: ruta === 'conceptos' }" to="/configuracion/conceptos">
              <i class="bi bi-tags"></i>Conceptos
            </router-link>
          </li>
          <li class="nav-item">
            <router-link class="nav-link" :class="{ active: ruta === 'descuentos-empleados' }" to="/configuracion/descuentos-empleados">
              <i class="bi bi-person-lines-fill"></i>Descuentos Empleados
            </router-link>
          </li>
          <li class="nav-item mt-3">
            <span class="text-uppercase text-white-50 small px-2">Planillas</span>
          </li>
          <li class="nav-item">
            <router-link class="nav-link" :class="{ active: ruta === 'planillas' }" to="/planillas">
              <i class="bi bi-file-earmark-spreadsheet"></i>Gestión de Planillas
            </router-link>
          </li>
          <li class="nav-item">
            <router-link class="nav-link" :class="{ active: ruta === 'papeletas' }" to="/papeletas">
              <i class="bi bi-printer"></i>Papeletas de Pago
            </router-link>
          </li>
          <li class="nav-item">
            <router-link class="nav-link" :class="{ active: ruta === 'planilla-imprimir' }" to="/planilla-imprimir">
              <i class="bi bi-table"></i>Imprimir Planilla
            </router-link>
          </li>
        </ul>
      </div>

      <div class="flex-grow-1 p-3 p-md-4">
        <router-view />
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAuthStore } from '../stores/auth'

const route = useRoute()
const router = useRouter()
const auth = useAuthStore()

const ruta = computed(() => route.name)

function cerrarSesion() {
  auth.logout()
  router.push('/login')
}
</script>
