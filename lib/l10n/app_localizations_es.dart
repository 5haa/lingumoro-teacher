import 'app_localizations.dart';

class AppLocalizationsEs extends AppLocalizations {
  // Common
  @override
  String get appName => 'LinguMoro';
  @override
  String get ok => 'OK';
  @override
  String get cancel => 'Cancelar';
  @override
  String get yes => 'Sí';
  @override
  String get no => 'No';
  @override
  String get error => 'Error';
  @override
  String get success => 'Éxito';
  @override
  String get loading => 'Cargando...';
  @override
  String get retry => 'Reintentar';
  @override
  String get requestTimedOut => 'La solicitud expiró. Por favor verifica tu conexión a internet.';
  @override
  String get failedToLoadStudents => 'Error al cargar estudiantes';
  @override
  String get save => 'Guardar';
  @override
  String get delete => 'Eliminar';
  @override
  String get edit => 'Editar';
  @override
  String get search => 'Buscar';
  @override
  String get filter => 'Filtrar';
  @override
  String get close => 'Cerrar';
  @override
  String get next => 'Siguiente';
  @override
  String get previous => 'Anterior';
  @override
  String get done => 'Hecho';
  @override
  String get skip => 'Omitir';
  @override
  String get and => 'y';
  @override
  String get or => 'o';
  
  // Navigation
  @override
  String get navHome => 'Inicio';
  @override
  String get navClasses => 'Clases';
  @override
  String get navPractice => 'Práctica';
  @override
  String get navChat => 'Chat';
  @override
  String get navProfile => 'Perfil';
  
  // Drawer/Settings
  @override
  String get settings => 'AJUSTES';
  @override
  String get contactUs => 'CONTÁCTANOS';
  @override
  String get aboutUs => 'SOBRE NOSOTROS';
  @override
  String get privacyPolicy => 'POLÍTICA DE PRIVACIDAD';
  @override
  String get termsConditions => 'TÉRMINOS Y CONDICIONES';
  @override
  String get changeLanguage => 'CAMBIAR IDIOMA';
  @override
  String get selectLanguage => 'Seleccionar Idioma';
  @override
  String get languageChanged => 'Idioma cambiado a Español';
  @override
  String get version => 'Versión 1.0.0';
  
  // Auth
  @override
  String get login => 'Iniciar Sesión';
  @override
  String get signup => 'Registrarse';
  @override
  String get logout => 'Cerrar Sesión';
  @override
  String get email => 'Correo Electrónico';
  @override
  String get password => 'Contraseña';
  @override
  String get confirmPassword => 'Confirmar Contraseña';
  @override
  String get fullName => 'Nombre Completo';
  @override
  String get forgotPassword => '¿Olvidaste tu contraseña?';
  @override
  String get forgotPasswordTitle => 'OLVIDÉ MI CONTRASEÑA';
  @override
  String get forgotPasswordDescription => 'Ingresa tu dirección de correo electrónico y te enviaremos un código de verificación para restablecer tu contraseña';
  @override
  String get pleaseEnterYourEmail => 'Por favor ingresa tu correo electrónico';
  @override
  String get verificationCodeSentToEmail => 'Código de verificación enviado a tu correo electrónico';
  @override
  String get failedToSendCode => 'Error al enviar código';
  @override
  String get sendCode => 'ENVIAR CÓDIGO';
  @override
  String get resetPassword => 'Restablecer Contraseña';
  @override
  String get resetPasswordTitle => 'RESTABLECER CONTRASEÑA';
  @override
  String get resetPasswordDescription => 'Ingresa tu nueva contraseña a continuación';
  @override
  String get enterNewPasswordBelow => 'Ingresa tu nueva contraseña a continuación';
  @override
  String get newPassword => 'Nueva Contraseña';
  @override
  String get confirmNewPassword => 'Confirmar Nueva Contraseña';
  @override
  String get passwordResetSuccessfully => '¡Contraseña restablecida exitosamente!';
  @override
  String get failedToResetPassword => 'Error al restablecer contraseña';
  @override
  String get userNotLoggedIn => 'Usuario no ha iniciado sesión';
  @override
  String get dontHaveAccount => '¿No tienes una cuenta?';
  @override
  String get alreadyHaveAccount => '¿Ya tienes una cuenta?';
  @override
  String get enterEmail => 'Ingresa tu correo electrónico';
  @override
  String get enterPassword => 'Ingresa tu contraseña';
  @override
  String get enterFullName => 'Ingresa tu nombre completo';
  @override
  String get passwordMismatch => 'Las contraseñas no coinciden';
  @override
  String get emailRequired => 'El correo electrónico es requerido';
  @override
  String get passwordRequired => 'La contraseña es requerida';
  @override
  String get fullNameRequired => 'El nombre completo es requerido';
  @override
  String get invalidEmail => 'Correo electrónico inválido';
  @override
  String get passwordTooShort => 'La contraseña debe tener al menos 6 caracteres';
  @override
  String get loginSuccess => 'Inicio de sesión exitoso';
  @override
  String get loginFailed => 'Error al iniciar sesión';
  @override
  String get signupSuccess => 'Registro exitoso';
  @override
  String get signupFailed => 'Error al registrarse';
  @override
  String get logoutConfirm => 'Cerrar Sesión';
  @override
  String get areYouSureLogout => '¿Estás seguro de que quieres cerrar sesión?';
  @override
  String get phoneNumber => 'Número de Teléfono';
  @override
  String get enterPhoneNumber => 'Ingresa tu número de teléfono';
  @override
  String get phoneNumberRequired => 'El número de teléfono es requerido';
  @override
  String get bio => 'Biografía';
  @override
  String get enterBio => 'Cuéntanos sobre ti';
  @override
  String get createAccount => 'Crear Cuenta';
  @override
  String get welcomeBack => 'Bienvenido de Nuevo';
  @override
  String get getStarted => 'Comenzar';
  
  // Home
  @override
  String get chooseYourClass => 'ELIGE TU CLASE';
  @override
  String get students => 'Estudiantes';
  @override
  String get teachers => 'Profesores';
  @override
  String get noLanguagesAvailable => 'No hay idiomas disponibles';
  @override
  String get selectLanguageFirst => 'Por favor selecciona un idioma primero';
  
  // Profile
  @override
  String get profile => 'PERFIL';
  @override
  String get editProfile => 'Editar Perfil';
  @override
  String get personalInformation => 'Información Personal';
  @override
  String get security => 'Seguridad';
  @override
  String get changePassword => 'Cambiar Contraseña';
  @override
  String get changePasswordTitle => 'CAMBIAR CONTRASEÑA';
  @override
  String changePasswordDescription(String email) => 'Para cambiar tu contraseña, necesitamos verificar tu identidad. Enviaremos un código de verificación a $email';
  @override
  String get sendVerificationCode => 'ENVIAR CÓDIGO DE VERIFICACIÓN';
  @override
  String get updatePassword => 'Actualiza tu contraseña';
  @override
  String get currentLevel => 'Nivel Actual';
  @override
  String get proMember => 'Miembro PRO';
  @override
  String get freeMember => 'Miembro Gratuito';
  @override
  String get upgrade => 'Mejorar';
  @override
  String get upgradeToPro => 'Mejorar a PRO';
  @override
  String get redeemVoucher => 'Canjea tu código de cupón';
  @override
  String get voucherCode => 'Código de Cupón';
  @override
  String get enterCodeHere => 'Ingresa el código aquí';
  @override
  String get redeem => 'Canjear';
  @override
  String get proBenefits => 'Beneficios PRO';
  @override
  String get unlimitedAccess => 'Acceso Ilimitado';
  @override
  String get unlimitedAccessDesc => 'Accede a todas las funciones sin restricciones';
  @override
  String get connectWithStudents => 'Conéctate con Estudiantes';
  @override
  String get connectWithStudentsDesc => 'Chatea y conéctate con otros aprendices de idiomas';
  @override
  String get practiceWithAI => 'Practica con IA';
  @override
  String get practiceWithAIDesc => 'Sesiones de práctica de idiomas interactivas con IA';
  @override
  String get enterVoucherCode => 'Por favor ingresa un código de cupón';
  @override
  String get voucherRedeemed => '¡Suscripción PRO activada!';
  @override
  String get voucherRedeemedDesc => 'días añadidos';
  @override
  String get invalidVoucher => 'Código de cupón inválido';
  @override
  String get expiresPro => 'Expira';
  @override
  String get unlimitedFeatures => 'Acceso ilimitado a todas las funciones';
  @override
  String get limitedFeatures => 'Funciones limitadas disponibles';
  @override
  String get languageLearner => 'Aprendiz de Idiomas';
  @override
  String get xpPoints => 'XP';
  @override
  String get xpToNextLevel => 'XP para Nivel';
  @override
  String get maxLevelReached => '¡Nivel Máximo Alcanzado!';
  
  // Level statuses
  @override
  String get levelBeginner => 'Principiante';
  @override
  String get levelIntermediate => 'Intermedio';
  @override
  String get levelAdvanced => 'Avanzado';
  @override
  String get levelExpert => 'Experto';
  @override
  String get levelMaster => 'Maestro';
  @override
  String get levelGrandMaster => 'Gran Maestro';
  @override
  String get levelLegend => 'Leyenda';
  @override
  String get levelMythic => 'Mítico';
  @override
  String get levelTranscendent => 'Trascendente';
  @override
  String get levelSupreme => 'Supremo';
  
  // Classes
  @override
  String get classes => 'CLASES';
  @override
  String get upcoming => 'Próximas';
  @override
  String get finished => 'Finalizadas';
  @override
  String get joinSession => 'Unirse a Sesión';
  @override
  String get sessionDetails => 'Detalles de Sesión';
  @override
  String get meetingLinkNotAvailable => 'Enlace de reunión no disponible aún. Por favor espera a que el profesor lo configure.';
  @override
  String get waitForTeacher => 'Espera al profesor';
  @override
  String get noUpcomingSessions => 'No hay sesiones próximas';
  @override
  String get noFinishedSessions => 'No hay sesiones finalizadas';
  @override
  String get sessionWith => 'Sesión con';
  @override
  String get packageType => 'Paquete';
  @override
  String get date => 'Fecha';
  @override
  String get time => 'Hora';
  @override
  String get duration => 'Duración';
  @override
  String get minutes => 'minutos';
  
  // Practice
  @override
  String get practice => 'PRÁCTICA';
  @override
  String get videos => 'Videos';
  @override
  String get quizPractice => 'Práctica de Cuestionario';
  @override
  String get reading => 'Lectura';
  @override
  String get aiVoice => 'Voz IA';
  @override
  String get watchedVideos => 'Vistos';
  @override
  String get totalVideos => 'Total';
  @override
  String get questionsAnswered => 'Preguntas';
  @override
  String get accuracy => 'Precisión';
  @override
  String get storiesGenerated => 'Generadas';
  @override
  String get storiesRemaining => 'Restantes';
  @override
  String get startPractice => 'Iniciar Práctica';
  @override
  String get continueWatching => 'Continuar Viendo';
  @override
  String get markAsWatched => 'Marcar como Visto';
  @override
  String get completedVideos => 'Completado';
  @override
  String get noPracticeAvailable => 'No hay práctica disponible';
  @override
  String get proFeature => 'Función PRO';
  @override
  String get upgradeToAccess => 'Mejora a PRO para acceder a esta función';
  
  // Chat
  @override
  String get chat => 'CHAT';
  @override
  String get messages => 'Mensajes';
  @override
  String get online => 'En línea';
  @override
  String get offline => 'Desconectado';
  @override
  String get typing => 'escribiendo...';
  @override
  String get typeMessage => 'Escribe un mensaje';
  @override
  String get sendMessage => 'Enviar';
  @override
  String get noMessages => 'No hay mensajes aún';
  @override
  String get startConversation => 'Iniciar una conversación';
  @override
  String get chatRequests => 'Solicitudes de Chat';
  @override
  String get noChatRequests => 'No hay solicitudes de chat';
  @override
  String get accept => 'Aceptar';
  @override
  String get decline => 'Rechazar';
  @override
  String get blocked => 'Bloqueado';
  @override
  String get unblock => 'Desbloquear';
  @override
  String get block => 'Bloquear';
  @override
  String get report => 'Reportar';
  
  // Teachers
  @override
  String get teachersList => 'PROFESORES';
  @override
  String get noTeachersAvailable => 'No Hay Profesores Disponibles';
  @override
  String get noTeachersForLanguage => 'No se encontraron profesores para';
  @override
  String get selectPackage => 'Seleccionar Paquete';
  @override
  String get selectDayTime => 'Seleccionar Día y Hora';
  @override
  String get bookSession => 'Reservar Sesión';
  @override
  String get sessionBooked => 'Sesión reservada exitosamente';
  @override
  String get bookingFailed => 'Error al reservar';
  @override
  String get availableSlots => 'Horarios Disponibles';
  @override
  String get noAvailableSlots => 'No hay horarios disponibles';
  @override
  String get selectTimeSlot => 'Selecciona un horario';
  @override
  String get teacherDetails => 'Detalles del Profesor';
  @override
  String get rating => 'Calificación';
  @override
  String get reviews => 'Reseñas';
  @override
  String get about => 'Acerca de';
  @override
  String get experience => 'Experiencia';
  @override
  String get languages => 'Idiomas';
  @override
  String get hourlyRate => 'Tarifa por Hora';
  @override
  String get perSession => 'por sesión';
  
  // Students
  @override
  String get studentsList => 'ESTUDIANTES';
  @override
  String get searchStudents => 'Buscar estudiantes...';
  @override
  String get noStudentsFound => 'No se encontraron estudiantes';
  @override
  String get studentsWillAppearHere => 'Los estudiantes aparecerán aquí una vez que se suscriban a tus cursos';
  @override
  String get sendChatRequest => 'Enviar Solicitud de Chat';
  @override
  String get chatRequestSent => 'Solicitud de chat enviada';
  @override
  String get alreadyChatting => 'Ya estás chateando';
  
  // Packages
  @override
  String get packages => 'PAQUETES';
  @override
  String get selectYourPackage => 'Selecciona tu Paquete';
  @override
  String get packageDetails => 'Detalles del Paquete';
  @override
  String get sessionsPerWeek => 'sesiones por semana';
  @override
  String get totalSessions => 'Total de Sesiones';
  @override
  String get price => 'Precio';
  @override
  String get subscribe => 'Suscribirse';
  @override
  String get subscriptionActive => 'Suscripción Activa';
  @override
  String get subscriptionExpired => 'Suscripción Expirada';
  
  // Notifications
  @override
  String get notifications => 'NOTIFICACIONES';
  @override
  String get notificationSettings => 'Ajustes de Notificaciones';
  @override
  String get noNotifications => 'No hay notificaciones';
  @override
  String get markAllRead => 'Marcar todo como leído';
  @override
  String get enableNotifications => 'Habilitar Notificaciones';
  @override
  String get sessionReminders => 'Recordatorios de Sesión';
  @override
  String get chatMessages => 'Mensajes de Chat';
  @override
  String get practiceReminders => 'Recordatorios de Práctica';
  @override
  String get allNotificationsMarkedRead => 'Todas las notificaciones marcadas como leídas';
  @override
  String get clearAllNotificationsTitle => 'Borrar Todas las Notificaciones';
  @override
  String get clearAllNotificationsMessage => '¿Estás seguro de que quieres borrar todas las notificaciones? Esta acción no se puede deshacer.';
  @override
  String get clearAllButton => 'Borrar Todo';
  @override
  String notificationsCleared(int count) => 'Se borraron $count notificaciones';
  @override
  String get readAll => 'Leer todo';
  @override
  String get clear => 'Borrar';
  @override
  String get youreAllCaughtUp => '¡Ya estás al día!';
  
  // Days of week
  @override
  String get monday => 'Lunes';
  @override
  String get tuesday => 'Martes';
  @override
  String get wednesday => 'Miércoles';
  @override
  String get thursday => 'Jueves';
  @override
  String get friday => 'Viernes';
  @override
  String get saturday => 'Sábado';
  @override
  String get sunday => 'Domingo';
  
  // Months
  @override
  String get january => 'Enero';
  @override
  String get february => 'Febrero';
  @override
  String get march => 'Marzo';
  @override
  String get april => 'Abril';
  @override
  String get may => 'Mayo';
  @override
  String get june => 'Junio';
  @override
  String get july => 'Julio';
  @override
  String get august => 'Agosto';
  @override
  String get september => 'Septiembre';
  @override
  String get october => 'Octubre';
  @override
  String get november => 'Noviembre';
  @override
  String get december => 'Diciembre';
  
  // Error messages
  @override
  String get errorLoadingData => 'Error al cargar datos';
  @override
  String get errorSavingData => 'Error al guardar datos';
  @override
  String get errorNoInternet => 'Sin conexión a internet';
  @override
  String get errorTryAgain => 'Por favor intenta de nuevo';
  @override
  String get errorUnknown => 'Ocurrió un error desconocido';
  @override
  String get noInternetConnection => 'Sin Conexión a Internet';
  
  // Success messages
  @override
  String get successSaved => 'Guardado exitosamente';
  @override
  String get successUpdated => 'Actualizado exitosamente';
  @override
  String get successDeleted => 'Eliminado exitosamente';
  
  // Validation
  @override
  String get fieldRequired => 'Este campo es requerido';
  @override
  String get invalidInput => 'Entrada inválida';
  @override
  String get tooShort => 'Demasiado corto';
  @override
  String get tooLong => 'Demasiado largo';
  
  // Settings screens
  @override
  String get aboutUsContent => 'Lingumoro es una plataforma de aprendizaje de idiomas que conecta estudiantes con profesores.';
  @override
  String get privacyPolicyContent => 'Tu privacidad es importante para nosotros. Recopilamos y usamos tus datos para proporcionar mejores servicios.';
  @override
  String get termsConditionsContent => 'Al usar esta aplicación, aceptas nuestros términos y condiciones.';
  
  // Contact
  @override
  String get couldNotOpenWhatsApp => 'No se pudo abrir WhatsApp';
  @override
  String get errorOpeningWhatsApp => 'Error al abrir WhatsApp';
  
  // Province/City selection
  @override
  String get chooseCity => 'Elegir Ciudad';
  @override
  String get selectProvince => 'Seleccionar Provincia';
  @override
  String get searchProvince => 'Buscar provincia...';
  @override
  String get pleaseSelectProvince => 'Por favor selecciona tu provincia';
  @override
  String get fillAllFields => 'Por favor completa todos los campos requeridos';
  @override
  String get confirmAccount => 'CONFIRMAR CUENTA';
  
  // Teacher-specific
  @override
  String get specialization => 'Especialización';
  @override
  String get specializationOptional => 'Especialización (opcional)';
  @override
  String get teacherAccount => 'Cuenta de Profesor';
  @override
  String get dashboard => 'TABLERO';
  @override
  String get quickActions => 'ACCIONES RÁPIDAS';
  @override
  String get schedule => 'Horario';
  @override
  String get sessions => 'Sesiones';
  @override
  String get languagesITeach => 'IDIOMAS QUE ENSEÑO';
  @override
  String get noLanguagesAssigned => 'Aún no hay idiomas asignados';
  @override
  String get upcomingSessions => 'Próximas';
  @override
  String get meetingLink => 'Enlace de Reunión';
  @override
  String get setDefaultMeetingLink => 'Establecer Enlace de Reunión Predeterminado';
  @override
  String get meetingLinkWillBeUsed => 'Este enlace se usará automáticamente para todas tus sesiones próximas.';
  @override
  String get studentsCanJoinUsingLink => 'Los estudiantes podrán unirse a las sesiones usando este enlace';
  @override
  String get meetingLinkUpdated => '¡Enlace de reunión actualizado exitosamente!';
  @override
  String get failedToUpdateMeetingLink => 'Error al actualizar enlace de reunión';
  @override
  String get viewAllReviews => 'Ver Todas las Reseñas';
  @override
  String get noReviewsYet => 'Aún no hay reseñas';
  @override
  String get totalRatings => 'Total de Calificaciones';
  
  // Point Awards
  @override
  String get awardPointsToStudents => 'Otorgar Puntos a Estudiantes';
  @override
  String get awardPointsTo => 'Otorgar Puntos a';
  @override
  String get currentLevelLabel => 'Nivel Actual:';
  @override
  String get currentPointsLabel => 'Puntos Actuales:';
  @override
  String get pointsAwardedByYou => 'Puntos otorgados por ti:';
  @override
  String get pointLimits => 'Límites de Puntos';
  @override
  String get selectPointsToAward => 'Seleccionar Puntos para Otorgar';
  @override
  String get totalPoints => 'Puntos Totales';
  @override
  String youveAwardedPointsToThisStudent(int points) => 'Has otorgado $points puntos a este estudiante';
  @override
  String get orEnterCustomAmount => 'O ingresa una cantidad personalizada';
  @override
  String get pleaseEnterOrSelectPoints => 'Por favor ingresa o selecciona puntos';
  @override
  String maxPointsPerAwardValidation(int max) => 'Máximo $max puntos por premio';
  @override
  String get addANote => 'Agregar una Nota';
  @override
  String get whyIsStudentReceivingPoints => '¿Por qué este estudiante está recibiendo estos puntos?';
  @override
  String get noteExample => 'Ejemplo: ¡Excelente participación en la clase de hoy!';
  @override
  String get pleaseAddNoteExplainingAward => 'Por favor agrega una nota explicando el premio';
  @override
  String get maxPerAward => 'Por premio';
  @override
  String get maxPerStudent => 'Máx. por estudiante:';
  @override
  String get maxPerDay => 'Máx. por día:';
  @override
  String get maxPerWeek => 'Máx. por semana:';
  @override
  String get pointsToAward => 'Puntos a Otorgar *';
  @override
  String get enterPoints => 'Ingresa puntos';
  @override
  String get pleaseEnterPoints => 'Por favor ingresa puntos';
  @override
  String get enterValidPositiveNumber => 'Por favor ingresa un número positivo válido';
  @override
  String get maxPointsPerAward => 'Máx. {max} puntos por otorgamiento';
  @override
  String get note => 'Nota *';
  @override
  String get whyAwardingPoints => '¿Por qué estás otorgando estos puntos?';
  @override
  String get explainWhyEarned => 'Explica por qué el estudiante ganó estos puntos';
  @override
  String get pleaseEnterNote => 'Por favor ingresa una nota';
  @override
  String get noteMinLength => 'La nota debe tener al menos 10 caracteres';
  @override
  String get awardPoints => 'Otorgar Puntos';
  @override
  String get pointsAwardedSuccessfully => '¡Puntos otorgados exitosamente! Nuevo nivel:';
  @override
  String get newLevel => 'Nuevo nivel:';
  @override
  String get failedToAwardPoints => 'Error al otorgar puntos';
  @override
  String get noStudentsEnrolled => 'Aún no hay estudiantes inscritos';
  @override
  String get levelLabel => 'Nivel';
  @override
  String get awardedByYou => 'Otorgados por ti:';
  @override
  String get award => 'Otorgar';
  
  // Create Session
  @override
  String get createSession => 'CREAR SESIÓN';
  @override
  String get selectStudent => 'Seleccionar Estudiante';
  @override
  String get noActiveSubscriptions => 'No se encontraron suscripciones activas';
  @override
  String get sessionSchedule => 'Horario de Sesión';
  @override
  String get dateLabel => 'Fecha';
  @override
  String get start => 'Inicio';
  @override
  String get end => 'Fin';
  @override
  String get createSessionButton => 'CREAR SESIÓN';
  @override
  String get selectStudentSubscription => 'Por favor selecciona una suscripción de estudiante';
  @override
  String get endTimeMustBeAfterStart => 'La hora de fin debe ser después de la hora de inicio';
  @override
  String get sessionCreatedSuccessfully => 'Sesión creada exitosamente';
  @override
  String get errorCreatingSession => 'Error al crear sesión:';
  @override
  String get sessionsLeft => 'sesiones restantes';
  
  // Timeslot Management
  @override
  String get manageTimeslots => 'GESTIONAR HORARIOS';
  @override
  String get timeslotsOverview => 'Resumen de Horarios';
  @override
  String get total => 'Total';
  @override
  String get available => 'Disponible';
  @override
  String get disabled => 'Deshabilitado';
  @override
  String get booked => 'Reservado';
  @override
  String get noTimeslotsYet => 'Aún No Hay Horarios';
  @override
  String get addScheduleToGenerate => 'Agrega un horario para generar horarios de 30 minutos';
  @override
  String get availableLabel => 'disponible';
  @override
  String get bookedLabel => 'reservado';
  @override
  String get disabledLabel => 'deshabilitado';
  @override
  String get enableAll => 'Habilitar Todo';
  @override
  String get disableAll => 'Deshabilitar Todo';
  @override
  String get cannotDisableOccupied => 'No se puede deshabilitar horario ocupado';
  @override
  String get timeslotEnabledSuccessfully => 'Horario habilitado exitosamente';
  @override
  String get timeslotDisabledSuccessfully => 'Horario deshabilitado exitosamente';
  @override
  String get failedToUpdateTimeslot => 'Error al actualizar horario';
  @override
  String get noAvailableSlotsToToggle => 'No hay horarios disponibles para cambiar';
  @override
  String get timeslotsEnabled => '{count} horarios habilitados';
  @override
  String get timeslotsDisabled => '{count} horarios deshabilitados';
  
  // Schedule management
  @override
  String get myScheduleTitle => 'MI HORARIO';
  @override
  String get noScheduleSet => 'No hay horario configurado';
  @override
  String get addYourAvailableTimeSlots => 'Añade tus horarios disponibles';
  @override
  String get addTimeSlot => 'Agregar Horario';
  @override
  String get deleteScheduleTitle => '¿Eliminar horario?';
  @override
  String get deleteScheduleMessage => '¿Estás seguro de que quieres eliminar este horario?';
  @override
  String get slotLabel => 'horario';
  @override
  String get slotsLabel => 'horarios';
  @override
  String get dayOfWeekLabel => 'Día de la semana';
  @override
  String get timeLabel => 'Hora';
  @override
  String get toLabel => 'a';
  
  // Common additional
  @override
  String get level => 'Nivel';
  @override
  String levelDisplay(int level) => 'Nivel $level';
  @override
  String get pts => 'pts';
  @override
  String awarded(int points) => 'Otorgados: $points';
  @override
  String get session => 'Sesión';
  @override
  String get minute => 'minuto';
  @override
  String get minutesPlural => 'minutos';
  
  // Chat additional
  @override
  String get chatDeletedSuccessfully => 'Chat eliminado exitosamente';
  @override
  String get failedToDeleteChat => 'Error al eliminar el chat. Por favor intenta de nuevo.';
  @override
  String get messageUnsent => 'Mensaje no enviado';
  @override
  String get downloadedToUnableToOpen => 'Descargado a: {filePath}\nNo se pudo abrir el archivo: {message}';
  
  // Classes additional
  @override
  String get errorLoadingSessions => 'Error al cargar sesiones:';
  @override
  String get errorJoiningSession => 'Error al unirse a la sesión:';
  @override
  String get teacherInformationNotAvailable => 'Información del profesor no disponible';
  @override
  String get unableToStartChat => 'No se pudo iniciar el chat. Por favor intenta de nuevo.';
  @override
  String get errorOpeningChat => 'Error al abrir el chat:';
  @override
  String get unableToLoadTeacherDetails => 'No se pudieron cargar los detalles del profesor';
  @override
  String get myClasses => 'MIS CLASES';
  @override
  String get noUpcomingClasses => 'No hay clases próximas';
  @override
  String get noFinishedClasses => 'No hay clases finalizadas';
  @override
  String get pullDownToRefresh => 'Desliza hacia abajo para actualizar';
  @override
  String get setMeetingLink => 'Establecer Enlace de Reunión';
  @override
  String get enterMeetingLinkHint => 'Ingresa enlace de reunión (Zoom, Google Meet, etc.)';
  @override
  String get meetingLinkUpdatedSuccessfully => 'Enlace de reunión actualizado exitosamente';
  @override
  String get sessionStarted => 'Sesión iniciada';
  @override
  String get endSessionTitle => 'Finalizar Sesión';
  @override
  String get endSessionMessage => '¿Estás seguro de que quieres finalizar esta sesión? Se marcará como completada y se descontará un punto de la suscripción.';
  @override
  String get sessionEndedSuccessfully => 'Sesión finalizada exitosamente';
  @override
  String get cancelSessionTitle => 'Cancelar Sesión';
  @override
  String get cancelSessionMessage => '¿Estás seguro de que quieres cancelar esta sesión? El estudiante será notificado.';
  @override
  String get reasonOptional => 'Razón (opcional)';
  @override
  String get enterCancellationReason => 'Ingresa la razón de cancelación...';
  @override
  String get back => 'Atrás';
  @override
  String get cancelledByTeacher => 'Cancelada por el profesor';
  @override
  String get sessionCancelledSuccessfully => 'Sesión cancelada exitosamente';
  @override
  String get failedToCancelSession => 'Error al cancelar sesión';
  @override
  String get deleteSessionTitle => 'Eliminar Sesión';
  @override
  String get deleteSessionMessage => '¿Estás seguro de que quieres eliminar esta sesión? Esta acción no se puede deshacer.';
  @override
  String get deleteButton => 'Eliminar';
  @override
  String get sessionDeletedSuccessfully => 'Sesión eliminada exitosamente';
  @override
  String get failedToDeleteSessionOnly => 'Error al eliminar sesión. Solo se pueden eliminar sesiones programadas creadas por el profesor.';
  @override
  String get pleaseSetMeetingLinkFirst => 'Por favor establece un enlace de reunión primero';
  @override
  String get studentInformationNotAvailable => 'Información del estudiante no disponible';
  @override
  String get studentPlaceholder => 'Estudiante';
  @override
  String get today => 'HOY';
  @override
  String get makeupClass => 'CLASE DE RECUPERACIÓN';
  @override
  String get manuallyCreated => 'CREADA MANUALMENTE';
  @override
  String get languagePlaceholder => 'Idioma';
  @override
  String get updateLink => 'Actualizar Enlace';
  @override
  String get setLink => 'Establecer Enlace';
  @override
  String get joinButton => 'Unirse';
  @override
  String get startButton => 'Iniciar';
  @override
  String get endButton => 'Finalizar';
  @override
  String get deleteSessionButton => 'Eliminar Sesión';
  @override
  String get cancelSessionButton => 'Cancelar Sesión';
  @override
  String get statusScheduled => 'Programada';
  @override
  String get statusReady => 'Lista';
  @override
  String get statusInProgress => 'En Progreso';
  @override
  String get statusCompleted => 'Completada';
  @override
  String get statusCancelled => 'Cancelada';
  @override
  String get statusMissed => 'Perdida';
  @override
  String get min => 'min';
  @override
  String get mon => 'Lun';
  @override
  String get tue => 'Mar';
  @override
  String get wed => 'Mié';
  @override
  String get thu => 'Jue';
  @override
  String get fri => 'Vie';
  @override
  String get sat => 'Sáb';
  @override
  String get sun => 'Dom';
  @override
  String get jan => 'Ene';
  @override
  String get feb => 'Feb';
  @override
  String get mar => 'Mar';
  @override
  String get apr => 'Abr';
  // may is already defined above - same in short form
  @override
  String get jun => 'Jun';
  @override
  String get jul => 'Jul';
  @override
  String get aug => 'Ago';
  @override
  String get sep => 'Sep';
  @override
  String get oct => 'Oct';
  @override
  String get nov => 'Nov';
  @override
  String get dec => 'Dic';
  
  // Profile additional
  @override
  String get allReviews => 'Todas las Reseñas';
  @override
  String get logoutTitle => 'Cerrar Sesión';
  @override
  String get logoutConfirmMessage => '¿Estás seguro de que quieres cerrar sesión?';
  @override
  String get logoutButton => 'Cerrar Sesión';
  @override
  String get logoutFailed => 'Error al cerrar sesión';
  @override
  String get personalInformationSection => 'Información Personal';
  @override
  String get editProfileTitle => 'Editar Perfil';
  @override
  String get updateProfileInfo => 'Actualiza tu información de perfil';
  @override
  String get securitySection => 'Seguridad';
  @override
  String get teacherPlaceholder => 'Profesor';
  @override
  String get languageTeacher => 'Profesor de Idiomas';
  
  // Profile page - additional
  @override
  String get profileTitle => 'PERFIL';
  @override
  String get aboutMe => 'Acerca de Mí';
  @override
  String get accountInformation => 'Información de la Cuenta';
  @override
  String get notAvailable => 'N/D';
  @override
  String get memberSince => 'Miembro Desde';
  @override
  String get recentReviews => 'Reseñas Recientes';
  @override
  String get viewAll => 'Ver Todas';
  @override
  String get updateYourPassword => 'Actualiza la contraseña de tu cuenta';
  @override
  String get logoutButtonText => 'CERRAR SESIÓN';
  @override
  String get defaultMeetingLink => 'Enlace de Reunión Predeterminado';
  @override
  String get editMeetingLinkTooltip => 'Editar Enlace de Reunión';
  @override
  String get meetingLinkNotSet => 'No configurado - Haz clic en editar para agregar tu enlace de reunión';
  @override
  String get setMeetingLinkMessage => 'Configura tu enlace de reunión para que los estudiantes puedan unirse a tus sesiones';
  
  // Chat file operations
  @override
  String get downloading => 'Descargando';
  @override
  String get downloadFailed => 'Error al descargar:';
  @override
  String get failedToLoadImage => 'Error al cargar la imagen';
  @override
  String get tapToRetry => 'Toca para reintentar';
  
  // Chat list screen
  @override
  String get messagesTitle => 'MENSAJES';
  @override
  String get searchMessages => 'Buscar mensajes...';
  @override
  String get showConversations => 'Mostrar Conversaciones';
  @override
  String get startNewChat => 'Iniciar Nuevo Chat';
  @override
  String get requestAccepted => '¡Solicitud aceptada!';
  @override
  String get failedToAcceptRequest => 'Error al aceptar solicitud';
  @override
  String get requestRejected => 'Solicitud rechazada';
  @override
  String get failedToRejectRequest => 'Error al rechazar solicitud';
  @override
  String get justNow => 'ahora';
  @override
  String minutesAgo(int minutes) => 'hace ${minutes}m';
  @override
  String get oneDayAgo => 'hace 1d';
  @override
  String daysAgo(int days) => 'hace ${days}d';
  @override
  String get noResultsFound => 'No se encontraron resultados';
  @override
  String get noMessagesYet => 'No hay mensajes aún';
  @override
  String get tryDifferentKeywords => 'Intenta buscar con diferentes palabras clave';
  @override
  String get startConversationWithStudents => 'Inicia una conversación con tus estudiantes';
  @override
  String get chatRequestTitle => 'Solicitud de Chat';
  @override
  String get noMessageProvided => 'No se proporcionó mensaje';
  @override
  String get sentChatRequest => 'Envió una solicitud de chat';
  @override
  String get deleteChat => 'Eliminar Chat';
  @override
  String get deleteChatQuestion => '¿Eliminar Chat?';
  @override
  String deleteChatConfirmation(String name) => '¿Estás seguro de que quieres eliminar este chat con $name? Esta acción no se puede deshacer.';
  @override
  String get noStudentsAvailable => 'No hay estudiantes disponibles';
  @override
  String get waitForStudentsToSubscribe => 'Espera a que los estudiantes se suscriban a tus cursos';
  @override
  String get imageAttachment => '🖼️ Imagen';
  @override
  String get voiceMessage => '🎤 Mensaje de voz';
  @override
  String get fileAttachment => '📎 Archivo';
  @override
  String get attachmentGeneric => '📎 Adjunto';
  @override
  String get startChatting => 'Comienza a chatear...';
  @override
  String get user => 'Usuario';
  
  // Edit Profile
  @override
  String get chooseProfilePicture => 'Elegir Foto de Perfil';
  @override
  String get chooseFromGallery => 'Elegir de la Galería';
  @override
  String get takeAPhoto => 'Tomar una Foto';
  @override
  String get removePhoto => 'Eliminar Foto';
  @override
  String errorPickingImage(String error) => 'Error al elegir imagen: $error';
  @override
  String get profileUpdatedSuccessfully => '¡Perfil actualizado exitosamente!';
  @override
  String failedToUpdateProfile(String error) => 'Error al actualizar perfil: $error';
  @override
  String get enterYourFullName => 'Ingresa tu nombre completo';
  @override
  String get pleaseEnterYourName => 'Por favor ingresa tu nombre';
  @override
  String get specializationExample => 'ej., Literatura Inglesa, Matemáticas';
  @override
  String get tellStudentsAboutYourself => 'Cuéntales a los estudiantes sobre ti...';
  @override
  String get introductionVideoYouTubeUrl => 'Video de Introducción (URL de YouTube)';
  @override
  String get youtubeUrlHint => 'https://www.youtube.com/watch?v=...';
  @override
  String get pleaseEnterValidYouTubeUrl => 'Por favor ingresa una URL válida de YouTube';
  @override
  String get zoomGoogleMeetEtc => 'Zoom, Google Meet, etc.';
  @override
  String get saveChanges => 'GUARDAR CAMBIOS';
  @override
  String get addPhoto => 'Agregar Foto';
  @override
  String get changePhoto => 'Cambiar Foto';
}

