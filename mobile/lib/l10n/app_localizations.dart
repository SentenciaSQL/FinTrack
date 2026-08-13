import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// No description provided for @appName.
  ///
  /// In es, this message translates to:
  /// **'FinTrack'**
  String get appName;

  /// No description provided for @dashboard.
  ///
  /// In es, this message translates to:
  /// **'Inicio'**
  String get dashboard;

  /// No description provided for @transactions.
  ///
  /// In es, this message translates to:
  /// **'Movimientos'**
  String get transactions;

  /// No description provided for @budgets.
  ///
  /// In es, this message translates to:
  /// **'Presupuestos'**
  String get budgets;

  /// No description provided for @reports.
  ///
  /// In es, this message translates to:
  /// **'Reportes'**
  String get reports;

  /// No description provided for @settings.
  ///
  /// In es, this message translates to:
  /// **'Configuración'**
  String get settings;

  /// No description provided for @income.
  ///
  /// In es, this message translates to:
  /// **'Ingresos'**
  String get income;

  /// No description provided for @expenses.
  ///
  /// In es, this message translates to:
  /// **'Gastos'**
  String get expenses;

  /// No description provided for @savings.
  ///
  /// In es, this message translates to:
  /// **'Ahorro'**
  String get savings;

  /// No description provided for @more.
  ///
  /// In es, this message translates to:
  /// **'Más'**
  String get more;

  /// No description provided for @home.
  ///
  /// In es, this message translates to:
  /// **'Inicio'**
  String get home;

  /// No description provided for @budget.
  ///
  /// In es, this message translates to:
  /// **'Presupuesto'**
  String get budget;

  /// No description provided for @login.
  ///
  /// In es, this message translates to:
  /// **'Iniciar sesión'**
  String get login;

  /// No description provided for @register.
  ///
  /// In es, this message translates to:
  /// **'Crear cuenta'**
  String get register;

  /// No description provided for @logout.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get logout;

  /// No description provided for @email.
  ///
  /// In es, this message translates to:
  /// **'Correo electrónico'**
  String get email;

  /// No description provided for @password.
  ///
  /// In es, this message translates to:
  /// **'Contraseña'**
  String get password;

  /// No description provided for @name.
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get name;

  /// No description provided for @save.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In es, this message translates to:
  /// **'Editar'**
  String get edit;

  /// No description provided for @add.
  ///
  /// In es, this message translates to:
  /// **'Agregar'**
  String get add;

  /// No description provided for @confirm.
  ///
  /// In es, this message translates to:
  /// **'Confirmar'**
  String get confirm;

  /// No description provided for @continueLabel.
  ///
  /// In es, this message translates to:
  /// **'Continuar'**
  String get continueLabel;

  /// No description provided for @skip.
  ///
  /// In es, this message translates to:
  /// **'Saltar'**
  String get skip;

  /// No description provided for @next.
  ///
  /// In es, this message translates to:
  /// **'Siguiente'**
  String get next;

  /// No description provided for @getStarted.
  ///
  /// In es, this message translates to:
  /// **'Comenzar'**
  String get getStarted;

  /// No description provided for @search.
  ///
  /// In es, this message translates to:
  /// **'Buscar'**
  String get search;

  /// No description provided for @filters.
  ///
  /// In es, this message translates to:
  /// **'Filtros'**
  String get filters;

  /// No description provided for @apply.
  ///
  /// In es, this message translates to:
  /// **'Aplicar'**
  String get apply;

  /// No description provided for @clear.
  ///
  /// In es, this message translates to:
  /// **'Limpiar'**
  String get clear;

  /// No description provided for @retry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get retry;

  /// No description provided for @loading.
  ///
  /// In es, this message translates to:
  /// **'Cargando...'**
  String get loading;

  /// No description provided for @seeAll.
  ///
  /// In es, this message translates to:
  /// **'Ver todo'**
  String get seeAll;

  /// No description provided for @notes.
  ///
  /// In es, this message translates to:
  /// **'Notas'**
  String get notes;

  /// No description provided for @optional.
  ///
  /// In es, this message translates to:
  /// **'Opcional'**
  String get optional;

  /// No description provided for @description.
  ///
  /// In es, this message translates to:
  /// **'Descripción'**
  String get description;

  /// No description provided for @amount.
  ///
  /// In es, this message translates to:
  /// **'Monto'**
  String get amount;

  /// No description provided for @date.
  ///
  /// In es, this message translates to:
  /// **'Fecha'**
  String get date;

  /// No description provided for @category.
  ///
  /// In es, this message translates to:
  /// **'Categoría'**
  String get category;

  /// No description provided for @type.
  ///
  /// In es, this message translates to:
  /// **'Tipo'**
  String get type;

  /// No description provided for @paymentMethod.
  ///
  /// In es, this message translates to:
  /// **'Método de pago'**
  String get paymentMethod;

  /// No description provided for @profile.
  ///
  /// In es, this message translates to:
  /// **'Perfil'**
  String get profile;

  /// No description provided for @categories.
  ///
  /// In es, this message translates to:
  /// **'Categorías'**
  String get categories;

  /// No description provided for @recurring.
  ///
  /// In es, this message translates to:
  /// **'Recurrentes'**
  String get recurring;

  /// No description provided for @savingsGoals.
  ///
  /// In es, this message translates to:
  /// **'Metas de ahorro'**
  String get savingsGoals;

  /// No description provided for @language.
  ///
  /// In es, this message translates to:
  /// **'Idioma'**
  String get language;

  /// No description provided for @theme.
  ///
  /// In es, this message translates to:
  /// **'Tema'**
  String get theme;

  /// No description provided for @currency.
  ///
  /// In es, this message translates to:
  /// **'Moneda'**
  String get currency;

  /// No description provided for @spanish.
  ///
  /// In es, this message translates to:
  /// **'Español'**
  String get spanish;

  /// No description provided for @english.
  ///
  /// In es, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @light.
  ///
  /// In es, this message translates to:
  /// **'Claro'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In es, this message translates to:
  /// **'Oscuro'**
  String get dark;

  /// No description provided for @system.
  ///
  /// In es, this message translates to:
  /// **'Sistema'**
  String get system;

  /// No description provided for @addExpense.
  ///
  /// In es, this message translates to:
  /// **'Registrar gasto'**
  String get addExpense;

  /// No description provided for @addIncome.
  ///
  /// In es, this message translates to:
  /// **'Registrar ingreso'**
  String get addIncome;

  /// No description provided for @editTransaction.
  ///
  /// In es, this message translates to:
  /// **'Editar movimiento'**
  String get editTransaction;

  /// No description provided for @transactionDetails.
  ///
  /// In es, this message translates to:
  /// **'Detalle del movimiento'**
  String get transactionDetails;

  /// No description provided for @newTransaction.
  ///
  /// In es, this message translates to:
  /// **'Nuevo movimiento'**
  String get newTransaction;

  /// No description provided for @onboardingTitle1.
  ///
  /// In es, this message translates to:
  /// **'Controla tus finanzas'**
  String get onboardingTitle1;

  /// No description provided for @onboardingBody1.
  ///
  /// In es, this message translates to:
  /// **'Registra tus ingresos y gastos fácilmente.'**
  String get onboardingBody1;

  /// No description provided for @onboardingTitle2.
  ///
  /// In es, this message translates to:
  /// **'Define tus presupuestos'**
  String get onboardingTitle2;

  /// No description provided for @onboardingBody2.
  ///
  /// In es, this message translates to:
  /// **'Controla cuánto quieres gastar cada mes.'**
  String get onboardingBody2;

  /// No description provided for @onboardingTitle3.
  ///
  /// In es, this message translates to:
  /// **'Alcanza tus objetivos'**
  String get onboardingTitle3;

  /// No description provided for @onboardingBody3.
  ///
  /// In es, this message translates to:
  /// **'Crea metas y sigue tu progreso financiero.'**
  String get onboardingBody3;

  /// No description provided for @loginSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Entra para continuar con tu panorama financiero.'**
  String get loginSubtitle;

  /// No description provided for @registerSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Crea tu cuenta y toma el control de tu dinero.'**
  String get registerSubtitle;

  /// No description provided for @noAccount.
  ///
  /// In es, this message translates to:
  /// **'¿No tienes una cuenta?'**
  String get noAccount;

  /// No description provided for @hasAccount.
  ///
  /// In es, this message translates to:
  /// **'¿Ya tienes una cuenta?'**
  String get hasAccount;

  /// No description provided for @forgotPassword.
  ///
  /// In es, this message translates to:
  /// **'¿Olvidaste tu contraseña?'**
  String get forgotPassword;

  /// No description provided for @currentBalance.
  ///
  /// In es, this message translates to:
  /// **'Balance actual'**
  String get currentBalance;

  /// No description provided for @monthlyIncome.
  ///
  /// In es, this message translates to:
  /// **'Ingresos del mes'**
  String get monthlyIncome;

  /// No description provided for @monthlyExpense.
  ///
  /// In es, this message translates to:
  /// **'Gastos del mes'**
  String get monthlyExpense;

  /// No description provided for @monthlySavings.
  ///
  /// In es, this message translates to:
  /// **'Ahorro del mes'**
  String get monthlySavings;

  /// No description provided for @budgetUsed.
  ///
  /// In es, this message translates to:
  /// **'Presupuesto utilizado'**
  String get budgetUsed;

  /// No description provided for @recentTransactions.
  ///
  /// In es, this message translates to:
  /// **'Movimientos recientes'**
  String get recentTransactions;

  /// No description provided for @incomeVsExpenses.
  ///
  /// In es, this message translates to:
  /// **'Ingresos vs gastos'**
  String get incomeVsExpenses;

  /// No description provided for @expensesByCategory.
  ///
  /// In es, this message translates to:
  /// **'Gastos por categoría'**
  String get expensesByCategory;

  /// No description provided for @emptyTransactions.
  ///
  /// In es, this message translates to:
  /// **'Todavía no tienes movimientos.'**
  String get emptyTransactions;

  /// No description provided for @emptyTransactionsHint.
  ///
  /// In es, this message translates to:
  /// **'Registra tu primer ingreso o gasto para comenzar.'**
  String get emptyTransactionsHint;

  /// No description provided for @emptyBudgets.
  ///
  /// In es, this message translates to:
  /// **'Todavía no tienes presupuestos.'**
  String get emptyBudgets;

  /// No description provided for @emptyBudgetsHint.
  ///
  /// In es, this message translates to:
  /// **'Crea un límite mensual por categoría para controlar tus gastos.'**
  String get emptyBudgetsHint;

  /// No description provided for @emptyGoals.
  ///
  /// In es, this message translates to:
  /// **'Todavía no tienes metas de ahorro.'**
  String get emptyGoals;

  /// No description provided for @emptyGoalsHint.
  ///
  /// In es, this message translates to:
  /// **'Crea una meta y sigue tu progreso hasta alcanzarla.'**
  String get emptyGoalsHint;

  /// No description provided for @emptyRecurring.
  ///
  /// In es, this message translates to:
  /// **'Todavía no tienes transacciones recurrentes.'**
  String get emptyRecurring;

  /// No description provided for @emptyRecurringHint.
  ///
  /// In es, this message translates to:
  /// **'Automatiza tu salario, alquiler o suscripciones.'**
  String get emptyRecurringHint;

  /// No description provided for @emptyCategories.
  ///
  /// In es, this message translates to:
  /// **'No hay categorías para mostrar.'**
  String get emptyCategories;

  /// No description provided for @emptyReports.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay datos suficientes para los reportes.'**
  String get emptyReports;

  /// No description provided for @emptyReportsHint.
  ///
  /// In es, this message translates to:
  /// **'Registra movimientos este mes para ver tus estadísticas.'**
  String get emptyReportsHint;

  /// No description provided for @errorGeneric.
  ///
  /// In es, this message translates to:
  /// **'Ocurrió un error. Inténtalo de nuevo.'**
  String get errorGeneric;

  /// No description provided for @spent.
  ///
  /// In es, this message translates to:
  /// **'Gastado'**
  String get spent;

  /// No description provided for @available.
  ///
  /// In es, this message translates to:
  /// **'Disponible'**
  String get available;

  /// No description provided for @target.
  ///
  /// In es, this message translates to:
  /// **'Objetivo'**
  String get target;

  /// No description provided for @saved.
  ///
  /// In es, this message translates to:
  /// **'Ahorrado'**
  String get saved;

  /// No description provided for @progress.
  ///
  /// In es, this message translates to:
  /// **'Progreso'**
  String get progress;

  /// No description provided for @contribute.
  ///
  /// In es, this message translates to:
  /// **'Aportar'**
  String get contribute;

  /// No description provided for @addContribution.
  ///
  /// In es, this message translates to:
  /// **'Agregar aporte'**
  String get addContribution;

  /// No description provided for @newBudget.
  ///
  /// In es, this message translates to:
  /// **'Nuevo presupuesto'**
  String get newBudget;

  /// No description provided for @editBudget.
  ///
  /// In es, this message translates to:
  /// **'Editar presupuesto'**
  String get editBudget;

  /// No description provided for @newGoal.
  ///
  /// In es, this message translates to:
  /// **'Nueva meta'**
  String get newGoal;

  /// No description provided for @editGoal.
  ///
  /// In es, this message translates to:
  /// **'Editar meta'**
  String get editGoal;

  /// No description provided for @newRecurring.
  ///
  /// In es, this message translates to:
  /// **'Nueva recurrente'**
  String get newRecurring;

  /// No description provided for @editRecurring.
  ///
  /// In es, this message translates to:
  /// **'Editar recurrente'**
  String get editRecurring;

  /// No description provided for @newCategory.
  ///
  /// In es, this message translates to:
  /// **'Nueva categoría'**
  String get newCategory;

  /// No description provided for @editCategory.
  ///
  /// In es, this message translates to:
  /// **'Editar categoría'**
  String get editCategory;

  /// No description provided for @frequency.
  ///
  /// In es, this message translates to:
  /// **'Frecuencia'**
  String get frequency;

  /// No description provided for @nextExecution.
  ///
  /// In es, this message translates to:
  /// **'Próxima ejecución'**
  String get nextExecution;

  /// No description provided for @active.
  ///
  /// In es, this message translates to:
  /// **'Activa'**
  String get active;

  /// No description provided for @inactive.
  ///
  /// In es, this message translates to:
  /// **'Inactiva'**
  String get inactive;

  /// No description provided for @month.
  ///
  /// In es, this message translates to:
  /// **'Mes'**
  String get month;

  /// No description provided for @year.
  ///
  /// In es, this message translates to:
  /// **'Año'**
  String get year;

  /// No description provided for @targetDate.
  ///
  /// In es, this message translates to:
  /// **'Fecha objetivo'**
  String get targetDate;

  /// No description provided for @targetAmount.
  ///
  /// In es, this message translates to:
  /// **'Monto objetivo'**
  String get targetAmount;

  /// No description provided for @currentAmount.
  ///
  /// In es, this message translates to:
  /// **'Monto actual'**
  String get currentAmount;

  /// No description provided for @icon.
  ///
  /// In es, this message translates to:
  /// **'Icono'**
  String get icon;

  /// No description provided for @customCategory.
  ///
  /// In es, this message translates to:
  /// **'Categoría personalizada'**
  String get customCategory;

  /// No description provided for @defaultCategory.
  ///
  /// In es, this message translates to:
  /// **'Predeterminada'**
  String get defaultCategory;

  /// No description provided for @cash.
  ///
  /// In es, this message translates to:
  /// **'Efectivo'**
  String get cash;

  /// No description provided for @debitCard.
  ///
  /// In es, this message translates to:
  /// **'Tarjeta de débito'**
  String get debitCard;

  /// No description provided for @creditCard.
  ///
  /// In es, this message translates to:
  /// **'Tarjeta de crédito'**
  String get creditCard;

  /// No description provided for @bankTransfer.
  ///
  /// In es, this message translates to:
  /// **'Transferencia bancaria'**
  String get bankTransfer;

  /// No description provided for @other.
  ///
  /// In es, this message translates to:
  /// **'Otro'**
  String get other;

  /// No description provided for @weekly.
  ///
  /// In es, this message translates to:
  /// **'Semanal'**
  String get weekly;

  /// No description provided for @biweekly.
  ///
  /// In es, this message translates to:
  /// **'Quincenal'**
  String get biweekly;

  /// No description provided for @monthly.
  ///
  /// In es, this message translates to:
  /// **'Mensual'**
  String get monthly;

  /// No description provided for @yearly.
  ///
  /// In es, this message translates to:
  /// **'Anual'**
  String get yearly;

  /// No description provided for @expense.
  ///
  /// In es, this message translates to:
  /// **'Gasto'**
  String get expense;

  /// No description provided for @catFood.
  ///
  /// In es, this message translates to:
  /// **'Alimentación'**
  String get catFood;

  /// No description provided for @catTransportation.
  ///
  /// In es, this message translates to:
  /// **'Transporte'**
  String get catTransportation;

  /// No description provided for @catHousing.
  ///
  /// In es, this message translates to:
  /// **'Vivienda'**
  String get catHousing;

  /// No description provided for @catUtilities.
  ///
  /// In es, this message translates to:
  /// **'Servicios'**
  String get catUtilities;

  /// No description provided for @catHealth.
  ///
  /// In es, this message translates to:
  /// **'Salud'**
  String get catHealth;

  /// No description provided for @catEducation.
  ///
  /// In es, this message translates to:
  /// **'Educación'**
  String get catEducation;

  /// No description provided for @catEntertainment.
  ///
  /// In es, this message translates to:
  /// **'Entretenimiento'**
  String get catEntertainment;

  /// No description provided for @catShopping.
  ///
  /// In es, this message translates to:
  /// **'Compras'**
  String get catShopping;

  /// No description provided for @catSubscriptions.
  ///
  /// In es, this message translates to:
  /// **'Suscripciones'**
  String get catSubscriptions;

  /// No description provided for @catTravel.
  ///
  /// In es, this message translates to:
  /// **'Viajes'**
  String get catTravel;

  /// No description provided for @catOther.
  ///
  /// In es, this message translates to:
  /// **'Otros'**
  String get catOther;

  /// No description provided for @catSalary.
  ///
  /// In es, this message translates to:
  /// **'Salario'**
  String get catSalary;

  /// No description provided for @catFreelance.
  ///
  /// In es, this message translates to:
  /// **'Freelance'**
  String get catFreelance;

  /// No description provided for @catBusiness.
  ///
  /// In es, this message translates to:
  /// **'Negocio'**
  String get catBusiness;

  /// No description provided for @catInvestments.
  ///
  /// In es, this message translates to:
  /// **'Inversiones'**
  String get catInvestments;

  /// No description provided for @catGifts.
  ///
  /// In es, this message translates to:
  /// **'Regalos'**
  String get catGifts;

  /// No description provided for @changePassword.
  ///
  /// In es, this message translates to:
  /// **'Cambiar contraseña'**
  String get changePassword;

  /// No description provided for @currentPassword.
  ///
  /// In es, this message translates to:
  /// **'Contraseña actual'**
  String get currentPassword;

  /// No description provided for @newPassword.
  ///
  /// In es, this message translates to:
  /// **'Nueva contraseña'**
  String get newPassword;

  /// No description provided for @preferredLanguage.
  ///
  /// In es, this message translates to:
  /// **'Idioma preferido'**
  String get preferredLanguage;

  /// No description provided for @preferredCurrency.
  ///
  /// In es, this message translates to:
  /// **'Moneda preferida'**
  String get preferredCurrency;

  /// No description provided for @loadDemoData.
  ///
  /// In es, this message translates to:
  /// **'Cargar datos de demostración'**
  String get loadDemoData;

  /// No description provided for @demoDataLoaded.
  ///
  /// In es, this message translates to:
  /// **'Datos de demostración cargados'**
  String get demoDataLoaded;

  /// No description provided for @logoutConfirmTitle.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get logoutConfirmTitle;

  /// No description provided for @logoutConfirmBody.
  ///
  /// In es, this message translates to:
  /// **'¿Seguro que quieres salir de tu cuenta?'**
  String get logoutConfirmBody;

  /// No description provided for @deleteConfirmTitle.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get deleteConfirmTitle;

  /// No description provided for @deleteConfirmBody.
  ///
  /// In es, this message translates to:
  /// **'Esta acción no se puede deshacer.'**
  String get deleteConfirmBody;

  /// No description provided for @passwordChanged.
  ///
  /// In es, this message translates to:
  /// **'Contraseña actualizada'**
  String get passwordChanged;

  /// No description provided for @profileUpdated.
  ///
  /// In es, this message translates to:
  /// **'Perfil actualizado'**
  String get profileUpdated;

  /// No description provided for @savedSuccessfully.
  ///
  /// In es, this message translates to:
  /// **'Guardado correctamente'**
  String get savedSuccessfully;

  /// No description provided for @deletedSuccessfully.
  ///
  /// In es, this message translates to:
  /// **'Eliminado correctamente'**
  String get deletedSuccessfully;

  /// No description provided for @requiredField.
  ///
  /// In es, this message translates to:
  /// **'Este campo es obligatorio'**
  String get requiredField;

  /// No description provided for @invalidEmail.
  ///
  /// In es, this message translates to:
  /// **'Ingresa un correo válido'**
  String get invalidEmail;

  /// No description provided for @passwordMin.
  ///
  /// In es, this message translates to:
  /// **'La contraseña debe tener al menos 8 caracteres'**
  String get passwordMin;

  /// No description provided for @amountGreaterThanZero.
  ///
  /// In es, this message translates to:
  /// **'El monto debe ser mayor que cero'**
  String get amountGreaterThanZero;

  /// No description provided for @categoryRequired.
  ///
  /// In es, this message translates to:
  /// **'Selecciona una categoría'**
  String get categoryRequired;

  /// No description provided for @dateRequired.
  ///
  /// In es, this message translates to:
  /// **'Selecciona una fecha'**
  String get dateRequired;

  /// No description provided for @descriptionTooLong.
  ///
  /// In es, this message translates to:
  /// **'La descripción es demasiado larga'**
  String get descriptionTooLong;

  /// No description provided for @errInvalidAmount.
  ///
  /// In es, this message translates to:
  /// **'El monto debe ser mayor que cero.'**
  String get errInvalidAmount;

  /// No description provided for @errInvalidEmail.
  ///
  /// In es, this message translates to:
  /// **'El correo electrónico no es válido.'**
  String get errInvalidEmail;

  /// No description provided for @errInvalidPassword.
  ///
  /// In es, this message translates to:
  /// **'La contraseña debe tener al menos 8 caracteres.'**
  String get errInvalidPassword;

  /// No description provided for @errEmailAlreadyExists.
  ///
  /// In es, this message translates to:
  /// **'Ya existe una cuenta con este correo.'**
  String get errEmailAlreadyExists;

  /// No description provided for @errInvalidCredentials.
  ///
  /// In es, this message translates to:
  /// **'Correo o contraseña incorrectos.'**
  String get errInvalidCredentials;

  /// No description provided for @errResourceNotFound.
  ///
  /// In es, this message translates to:
  /// **'No encontramos ese recurso.'**
  String get errResourceNotFound;

  /// No description provided for @errForbidden.
  ///
  /// In es, this message translates to:
  /// **'No tienes permiso para esta acción.'**
  String get errForbidden;

  /// No description provided for @errValidation.
  ///
  /// In es, this message translates to:
  /// **'Revisa los datos e inténtalo de nuevo.'**
  String get errValidation;

  /// No description provided for @errUnauthorized.
  ///
  /// In es, this message translates to:
  /// **'Tu sesión expiró. Inicia sesión otra vez.'**
  String get errUnauthorized;

  /// No description provided for @errCurrentPasswordIncorrect.
  ///
  /// In es, this message translates to:
  /// **'La contraseña actual es incorrecta.'**
  String get errCurrentPasswordIncorrect;

  /// No description provided for @errBudgetAlreadyExists.
  ///
  /// In es, this message translates to:
  /// **'Ya existe un presupuesto para esta categoría y mes.'**
  String get errBudgetAlreadyExists;

  /// No description provided for @errCannotDeleteDefaultCategory.
  ///
  /// In es, this message translates to:
  /// **'Las categorías predeterminadas no se pueden eliminar.'**
  String get errCannotDeleteDefaultCategory;

  /// No description provided for @errCategoryTypeMismatch.
  ///
  /// In es, this message translates to:
  /// **'La categoría no coincide con el tipo de movimiento.'**
  String get errCategoryTypeMismatch;

  /// No description provided for @budgetStatusOk.
  ///
  /// In es, this message translates to:
  /// **'Dentro del límite'**
  String get budgetStatusOk;

  /// No description provided for @budgetStatusWarning.
  ///
  /// In es, this message translates to:
  /// **'Cerca del límite'**
  String get budgetStatusWarning;

  /// No description provided for @budgetStatusReached.
  ///
  /// In es, this message translates to:
  /// **'Límite alcanzado'**
  String get budgetStatusReached;

  /// No description provided for @budgetStatusExceeded.
  ///
  /// In es, this message translates to:
  /// **'Presupuesto excedido'**
  String get budgetStatusExceeded;

  /// No description provided for @topCategories.
  ///
  /// In es, this message translates to:
  /// **'Top 5 categorías'**
  String get topCategories;

  /// No description provided for @balanceHistory.
  ///
  /// In es, this message translates to:
  /// **'Historial de balance'**
  String get balanceHistory;

  /// No description provided for @monthlyEvolution.
  ///
  /// In es, this message translates to:
  /// **'Evolución mensual'**
  String get monthlyEvolution;

  /// No description provided for @thisMonth.
  ///
  /// In es, this message translates to:
  /// **'Este mes'**
  String get thisMonth;

  /// No description provided for @all.
  ///
  /// In es, this message translates to:
  /// **'Todos'**
  String get all;

  /// No description provided for @sortBy.
  ///
  /// In es, this message translates to:
  /// **'Ordenar por'**
  String get sortBy;

  /// No description provided for @sortDate.
  ///
  /// In es, this message translates to:
  /// **'Fecha'**
  String get sortDate;

  /// No description provided for @sortAmount.
  ///
  /// In es, this message translates to:
  /// **'Monto'**
  String get sortAmount;

  /// No description provided for @minAmount.
  ///
  /// In es, this message translates to:
  /// **'Monto mínimo'**
  String get minAmount;

  /// No description provided for @maxAmount.
  ///
  /// In es, this message translates to:
  /// **'Monto máximo'**
  String get maxAmount;

  /// No description provided for @startDate.
  ///
  /// In es, this message translates to:
  /// **'Desde'**
  String get startDate;

  /// No description provided for @endDate.
  ///
  /// In es, this message translates to:
  /// **'Hasta'**
  String get endDate;

  /// No description provided for @notifications.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones'**
  String get notifications;

  /// No description provided for @dailyReminderTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Cómo va tu día?'**
  String get dailyReminderTitle;

  /// No description provided for @dailyReminderBody.
  ///
  /// In es, this message translates to:
  /// **'Registra tus gastos de hoy en FinTrack.'**
  String get dailyReminderBody;

  /// No description provided for @budgetWarningTitle.
  ///
  /// In es, this message translates to:
  /// **'Presupuesto al 80%'**
  String get budgetWarningTitle;

  /// No description provided for @budgetWarningBody.
  ///
  /// In es, this message translates to:
  /// **'Estás cerca del límite en {category}.'**
  String budgetWarningBody(String category);

  /// No description provided for @budgetExceededTitle.
  ///
  /// In es, this message translates to:
  /// **'Presupuesto excedido'**
  String get budgetExceededTitle;

  /// No description provided for @budgetExceededBody.
  ///
  /// In es, this message translates to:
  /// **'Superaste el presupuesto de {category}.'**
  String budgetExceededBody(String category);

  /// No description provided for @goalAlmostTitle.
  ///
  /// In es, this message translates to:
  /// **'Meta casi lista'**
  String get goalAlmostTitle;

  /// No description provided for @goalAlmostBody.
  ///
  /// In es, this message translates to:
  /// **'Tu meta {name} está cerca de completarse.'**
  String goalAlmostBody(String name);

  /// No description provided for @recurringSoonTitle.
  ///
  /// In es, this message translates to:
  /// **'Movimiento recurrente próximo'**
  String get recurringSoonTitle;

  /// No description provided for @recurringSoonBody.
  ///
  /// In es, this message translates to:
  /// **'{description} se ejecutará pronto.'**
  String recurringSoonBody(String description);

  /// No description provided for @appearance.
  ///
  /// In es, this message translates to:
  /// **'Apariencia'**
  String get appearance;

  /// No description provided for @account.
  ///
  /// In es, this message translates to:
  /// **'Cuenta'**
  String get account;

  /// No description provided for @developer.
  ///
  /// In es, this message translates to:
  /// **'Desarrollador'**
  String get developer;

  /// No description provided for @about.
  ///
  /// In es, this message translates to:
  /// **'Acerca de'**
  String get about;

  /// No description provided for @aboutBody.
  ///
  /// In es, this message translates to:
  /// **'FinTrack te ayuda a registrar ingresos, controlar presupuestos y alcanzar metas de ahorro.'**
  String get aboutBody;

  /// No description provided for @version.
  ///
  /// In es, this message translates to:
  /// **'Versión 1.0.0'**
  String get version;

  /// No description provided for @contributions.
  ///
  /// In es, this message translates to:
  /// **'Aportes'**
  String get contributions;

  /// No description provided for @noContributions.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay aportes.'**
  String get noContributions;

  /// No description provided for @percentUsed.
  ///
  /// In es, this message translates to:
  /// **'{percent}%'**
  String percentUsed(String percent);

  /// No description provided for @welcomeBack.
  ///
  /// In es, this message translates to:
  /// **'Hola, {name}'**
  String welcomeBack(String name);

  /// No description provided for @splashTagline.
  ///
  /// In es, this message translates to:
  /// **'Tu dinero, bajo control.'**
  String get splashTagline;

  /// No description provided for @createAccount.
  ///
  /// In es, this message translates to:
  /// **'Crear cuenta'**
  String get createAccount;

  /// No description provided for @signIn.
  ///
  /// In es, this message translates to:
  /// **'Entrar'**
  String get signIn;

  /// No description provided for @selectCategory.
  ///
  /// In es, this message translates to:
  /// **'Selecciona una categoría'**
  String get selectCategory;

  /// No description provided for @selectPayment.
  ///
  /// In es, this message translates to:
  /// **'Método de pago'**
  String get selectPayment;

  /// No description provided for @filterTransactions.
  ///
  /// In es, this message translates to:
  /// **'Filtrar movimientos'**
  String get filterTransactions;

  /// No description provided for @moreOptions.
  ///
  /// In es, this message translates to:
  /// **'Más opciones'**
  String get moreOptions;

  /// No description provided for @languageAndRegion.
  ///
  /// In es, this message translates to:
  /// **'Idioma y región'**
  String get languageAndRegion;

  /// No description provided for @security.
  ///
  /// In es, this message translates to:
  /// **'Seguridad'**
  String get security;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
