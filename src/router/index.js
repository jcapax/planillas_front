import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '../stores/auth'

const routes = [
  {
    path: '/login',
    name: 'login',
    component: () => import('../views/LoginView.vue'),
    meta: { public: true }
  },
  {
    path: '/',
    component: () => import('../layouts/MainLayout.vue'),
    children: [
      { path: '', redirect: '/dashboard' },
      { path: 'dashboard', name: 'dashboard', component: () => import('../views/DashboardView.vue') },
      {
        path: 'configuracion',
        name: 'configuracion',
        component: () => import('../views/config/ConfiguracionView.vue'),
        children: [
          { path: '', redirect: '/configuracion/empresa' },
          { path: 'empresa', name: 'empresa', component: () => import('../views/config/EmpresaView.vue') },
          { path: 'empleados', name: 'empleados', component: () => import('../views/config/EmpleadosView.vue') },
          { path: 'parametros', name: 'parametros', component: () => import('../views/config/ParametrosView.vue') },
          { path: 'bono-antiguedad', name: 'bono-antiguedad', component: () => import('../views/config/BonoAntiguedadView.vue') },
          { path: 'conceptos', name: 'conceptos', component: () => import('../views/config/ConceptosView.vue') }
        ]
      },
      { path: 'planillas', name: 'planillas', component: () => import('../views/PlanillasView.vue') }
    ]
  },
  { path: '/:pathMatch(.*)*', redirect: '/dashboard' }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

router.beforeEach((to) => {
  const auth = useAuthStore()
  if (!to.meta.public && !auth.isAuthenticated) {
    return { name: 'login' }
  }
  if (to.name === 'login' && auth.isAuthenticated) {
    return { name: 'dashboard' }
  }
})

export default router
