# 💰 Modelo de Monetización — Clock.Do (Clock.Do Pro)

Este documento detalla la estrategia de negocio, estructura de precios, división de características (*Freemium vs Pro*), tácticas de conversión y el plan técnico de implementación para monetizar **Clock.Do** de forma sostenible y rentable.

---

## 🎯 1. Propuesta de Valor y Estrategia Central

Clock.Do combina la planificación visual de **Time-Blocking Radial (reloj analógico)** con la gestión de listas **ToDo**.

* **Mercado Objetivo**: Profesionales, freelancers, estudiantes universitarios y personas con TDAH / ADHD que necesitan ver su tiempo de forma intuitiva en lugar de listas aburridas.
* **Modelo Elegido**: **Freemium Híbrido** (Suscripción recurrente con opción de compra vitalicia *Lifetime*).
* **Objetivo de Retención**: Proporcionar una experiencia gratuita excelente que enganche al usuario en su rutina diaria, y ofrecer funciones de conveniencia y automatización como incentivo para actualizar a **Clock.Do Pro**.

---

## ⚖️ 2. Matriz de Características: Versión Gratis vs Clock.Do Pro

| Característica | 🆓 Clock.Do Free | 💎 Clock.Do Pro |
| :--- | :---: | :---: |
| **Reloj Radial Analógico (12h y 24h)** | ✅ Ilimitado | ✅ Ilimitado |
| **Creación interactiva de tareas por arrastre** | ✅ Incluido | ✅ Incluido |
| **Lista de Tareas ToDo (Backlog)** | ✅ Incluido | ✅ Incluido |
| **Modo Lupa (Zoom e Inspector)** | ✅ Incluido | ✅ Incluido |
| **Notificaciones y Recordatorios Locales** | ✅ 1 aviso por tarea | 🚀 Avisos múltiples personalizables |
| **Sincronización con Google Calendar / Apple / Outlook** | ❌ No | 🚀 **Bidireccional en tiempo real** |
| **Widgets para Pantalla de Inicio y Bloqueo** | ❌ No | 🚀 **Mini Reloj Radial en Widget** |
| **Estadísticas y Reportes de Distribución de Tiempo** | ❌ No | 🚀 **Gráficos semanales y mensuales** |
| **Temporizador Pomodoro / Modo Enfoque en el Centro** | ❌ No | 🚀 **Con sonidos ambientales relajantes** |
| **Tareas Recurrentes y Rutinas Diarias** | ❌ No | 🚀 **Repetición automática programable** |
| **Temas Exclusivos y Paletas de Colores** | 🎨 Claro / Oscuro estándar | 🚀 **OLED Negro Puro, Neón, Cyberpunk, etc.** |
| **Exportación de Reportes (PDF / CSV / Excel)** | ❌ No | 🚀 **Timesheets para clientes y trabajo** |
| **Copia de Seguridad en la Nube y Multi-dispositivo** | ❌ Solo local | 🚀 **Sincronización Cloud segura** |

---

## 🏷️ 3. Estructura de Precios Recomendada

La combinación de **anual con prueba gratuita** + **opción vitalicia (Lifetime)** es el estándar con mayor tasa de conversión en apps de productividad:

| Plan | Precio sugerido (USD) | Beneficio para el usuario | Rol estratégico |
| :--- | :---: | :---: | :---: |
| **Mensual** | **$2.99 / mes** | Flexibilidad total, sin compromiso a largo plazo | Ancla de precio alto |
| **Anual (Recomendado)** | **$14.99 / año** *(~$1.25/mes)* | **58% de descuento** + 7 días de prueba gratis | **Principal motor de ingresos (MRR/ARR)** |
| **Lifetime (De por vida)** | **$29.99** *(Pago único)* | Paga una sola vez y ten acceso a todas las futuras versiones | Conversión de usuarios reacios a suscripciones |

> 💡 *Nota*: Ajustar precios por paridad de poder adquisitivo (PPP) mediante Google Play Console y App Store Connect para mercados de América Latina y Europa.

---

## 🚀 4. Los 4 Grandes Disparadores de Compra (*Value Drivers*)

Los usuarios deciden pagar por Clock.Do Pro principalmente por estas 4 utilidades:

### 1. 🔄 Sincronización con Calendarios Externos
* Al conectar Google Calendar o Apple Calendar, las reuniones de trabajo y compromisos aparecen automáticamente como arcos de color en el reloj radial.
* Elimina la fricción de tener que anotar las cosas dos veces.

### 2. 📱 Widgets de Pantalla de Inicio (Home & Lock Screen)
* Poder ver qué tarea te toca hacer ahora y la siguiente sin desbloquear el móvil o sin entrar a la app.
* Es la función con mayor solicitud en apps de planificación diaria.

### 3. ⏱️ Temporizador Pomodoro Integrado
* Al tocar una tarea en el reloj, el centro se convierte en un contador Pomodoro (ej. 25 min enfoque / 5 min descanso) con sonidos de fondo (lluvia, café, ruido blanco) para mantener la concentración.

### 4. 📊 Analítica de Productividad Personal
* Descubrir visualmente a qué se le fue el día: *"Esta semana pasaste 24h en Trabajo, 8h en Estudio y 5h en Salud"*.

---

## 📈 5. Estrategia de Conversión y Embudos (Funnels)

1. **Onboarding suave (Primeros 3 días)**:
   - Permitir al usuario explorar la app sin pop-ups agresivos para que experimente el valor del reloj radial (*Momento Ajá!*).
2. **Disparadores Contextuales**:
   - Si el usuario intenta agregar una tarea repetitiva o conectar su calendario, abrir una ventana elegante (Paywall) explicando los beneficios de Clock.Do Pro con opción de prueba gratuita de 7 días.
3. **Prueba Gratuita sin Riesgo (7-Day Free Trial)**:
   - Recordatorio automático 2 días antes de que finalice la prueba gratuita para generar confianza y reducir reembolsos.
4. **Desbloqueo Recompensado Opcional (Rewarded Ads)**:
   - Para usuarios de países emergentes o que no poseen tarjeta de crédito, permitir ver un video corto (15s) para desbloquear un tema premium o exportar un reporte puntual por 24h.

---

## 🛠️ 6. Plan de Implementación Técnica en Flutter

Para integrar pagos de manera rápida, segura y multiplataforma (Android & iOS):

1. **Gestión de Compras**:
   - Usar **RevenueCat** (`purchases_flutter`), el SDK líder de la industria que maneja recibos, suscripciones, compras Lifetime y pruebas gratis tanto en Google Play Billing como en Apple StoreKit con pocas líneas de código.
2. **Sincronización con Google Calendar**:
   - Usar `googleapis` + `google_sign_in` para consultar eventos vía OAuth2 y convertirlos a `TimeBlock`.
3. **Widgets Nativos**:
   - Usar `home_widget` en Flutter para actualizar el canvas del widget nativo en Android (AppWidget) e iOS (WidgetKit).
