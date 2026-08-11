<template>
  <div class="login-wrapper">
    <div class="card login-card shadow-lg">
      <div class="card-body p-5">
        <div class="text-center mb-4">
          <i class="bi bi-clipboard2-pulse display-4 text-primary"></i>
          <h2 class="mt-3 mb-0 fw-bold">Sucre Sureña</h2>
          <p class="text-muted">Control de Planillas Salariales</p>
        </div>

        <form @submit.prevent="submit">
          <div class="mb-3">
            <label class="form-label">Usuario</label>
            <input
              v-model="username"
              type="text"
              class="form-control"
              placeholder="Ingrese su usuario"
              required
              autocomplete="username"
            />
          </div>
          <div class="mb-4">
            <label class="form-label">Contraseña</label>
            <input
              v-model="password"
              type="password"
              class="form-control"
              placeholder="Ingrese su contraseña"
              required
              autocomplete="current-password"
            />
          </div>

          <div v-if="error" class="alert alert-danger py-2">{{ error }}</div>

          <button class="btn btn-primary w-100" :disabled="loading">
            <span v-if="loading" class="spinner-border spinner-border-sm me-2"></span>
            Ingresar
          </button>
        </form>

        <p class="text-muted small text-center mt-4 mb-0">
          Usuario por defecto: <code>admin</code> / <code>admin123</code>
        </p>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '../stores/auth'
import { mensajeError } from '../services/api'

const router = useRouter()
const auth = useAuthStore()

const username = ref('')
const password = ref('')
const loading = ref(false)
const error = ref('')

async function submit() {
  error.value = ''
  loading.value = true
  try {
    await auth.login(username.value, password.value)
    router.push('/dashboard')
  } catch (e) {
    error.value = mensajeError(e, 'No se pudo iniciar sesión')
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
.login-wrapper {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  background: linear-gradient(135deg, #0d3a6d, #1e4a8a);
}
.login-card {
  width: 100%;
  max-width: 420px;
  border: none;
  border-radius: 1rem;
}
</style>
