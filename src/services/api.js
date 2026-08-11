import axios from 'axios'

const api = axios.create({
  baseURL: '/api',
  headers: { 'Content-Type': 'application/json' }
})

api.interceptors.request.use((config) => {
  const token = localStorage.getItem('token')
  if (token) {
    config.headers.Authorization = `Bearer ${token}`
  }
  return config
})

api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response && error.response.status === 401) {
      localStorage.removeItem('token')
      localStorage.removeItem('user')
      if (window.location.pathname !== '/login') {
        window.location.href = '/login'
      }
    }
    return Promise.reject(error)
  }
)

export function mensajeError(error, fallback = 'Ocurrió un error') {
  if (error.response && error.response.data) {
    const data = error.response.data
    if (typeof data === 'string') return data
    if (data.error) return data.error
    if (data.message) return data.message
    return Object.values(data).join(', ')
  }
  return error.message || fallback
}

export default api
