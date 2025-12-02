import 'package:flutter/material.dart';
import 'app_localizations_en.dart';
import 'app_localizations_ar.dart';
import 'app_localizations_es.dart';

abstract class AppLocalizations {
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = [
    delegate,
  ];

  static const List<Locale> supportedLocales = [
    Locale('en', ''),
    Locale('ar', ''),
    Locale('es', ''),
  ];

  // Common
  String get appName;
  String get ok;
  String get cancel;
  String get yes;
  String get no;
  String get error;
  String get success;
  String get loading;
  String get retry;
  String get requestTimedOut;
  String get failedToLoadStudents;
  String get save;
  String get delete;
  String get edit;
  String get search;
  String get filter;
  String get close;
  String get next;
  String get previous;
  String get done;
  String get skip;
  String get and;
  String get or;
  
  // Navigation
  String get navHome;
  String get navClasses;
  String get navPractice;
  String get navChat;
  String get navProfile;
  
  // Drawer/Settings
  String get settings;
  String get contactUs;
  String get aboutUs;
  String get privacyPolicy;
  String get termsConditions;
  String get changeLanguage;
  String get selectLanguage;
  String get languageChanged;
  String get version;
  
  // Auth
  String get login;
  String get signup;
  String get logout;
  String get email;
  String get password;
  String get confirmPassword;
  String get fullName;
  String get forgotPassword;
  String get forgotPasswordTitle;
  String get forgotPasswordDescription;
  String get pleaseEnterYourEmail;
  String get verificationCodeSentToEmail;
  String get failedToSendCode;
  String get sendCode;
  String get resetPassword;
  String get resetPasswordTitle;
  String get resetPasswordDescription;
  String get enterNewPasswordBelow;
  String get newPassword;
  String get confirmNewPassword;
  String get passwordResetSuccessfully;
  String get failedToResetPassword;
  String get userNotLoggedIn;
  String get dontHaveAccount;
  String get alreadyHaveAccount;
  String get enterEmail;
  String get enterPassword;
  String get enterFullName;
  String get passwordMismatch;
  String get emailRequired;
  String get passwordRequired;
  String get fullNameRequired;
  String get invalidEmail;
  String get passwordTooShort;
  String get loginSuccess;
  String get loginFailed;
  String get signupSuccess;
  String get signupFailed;
  String get logoutConfirm;
  String get areYouSureLogout;
  String get phoneNumber;
  String get enterPhoneNumber;
  String get phoneNumberRequired;
  String get bio;
  String get enterBio;
  String get createAccount;
  String get welcomeBack;
  String get getStarted;
  
  // Home
  String get chooseYourClass;
  String get students;
  String get teachers;
  String get noLanguagesAvailable;
  String get selectLanguageFirst;
  
  // Profile
  String get profile;
  String get editProfile;
  String get personalInformation;
  String get security;
  String get changePassword;
  String get changePasswordTitle;
  String changePasswordDescription(String email);
  String get sendVerificationCode;
  String get updatePassword;
  String get currentLevel;
  String get proMember;
  String get freeMember;
  String get upgrade;
  String get upgradeToPro;
  String get redeemVoucher;
  String get voucherCode;
  String get enterCodeHere;
  String get redeem;
  String get proBenefits;
  String get unlimitedAccess;
  String get unlimitedAccessDesc;
  String get connectWithStudents;
  String get connectWithStudentsDesc;
  String get practiceWithAI;
  String get practiceWithAIDesc;
  String get enterVoucherCode;
  String get voucherRedeemed;
  String get voucherRedeemedDesc;
  String get invalidVoucher;
  String get expiresPro;
  String get unlimitedFeatures;
  String get limitedFeatures;
  String get languageLearner;
  String get xpPoints;
  String get xpToNextLevel;
  String get maxLevelReached;
  
  // Level statuses
  String get levelBeginner;
  String get levelIntermediate;
  String get levelAdvanced;
  String get levelExpert;
  String get levelMaster;
  String get levelGrandMaster;
  String get levelLegend;
  String get levelMythic;
  String get levelTranscendent;
  String get levelSupreme;
  
  // Classes
  String get classes;
  String get upcoming;
  String get finished;
  String get joinSession;
  String get sessionDetails;
  String get meetingLinkNotAvailable;
  String get waitForTeacher;
  String get noUpcomingSessions;
  String get noFinishedSessions;
  String get sessionWith;
  String get packageType;
  String get date;
  String get time;
  String get duration;
  String get minutes;
  
  // Practice
  String get practice;
  String get videos;
  String get quizPractice;
  String get reading;
  String get aiVoice;
  String get watchedVideos;
  String get totalVideos;
  String get questionsAnswered;
  String get accuracy;
  String get storiesGenerated;
  String get storiesRemaining;
  String get startPractice;
  String get continueWatching;
  String get markAsWatched;
  String get completedVideos;
  String get noPracticeAvailable;
  String get proFeature;
  String get upgradeToAccess;
  
  // Chat
  String get chat;
  String get messages;
  String get online;
  String get offline;
  String get typing;
  String get typeMessage;
  String get sendMessage;
  String get noMessages;
  String get startConversation;
  String get chatRequests;
  String get noChatRequests;
  String get accept;
  String get decline;
  String get blocked;
  String get unblock;
  String get block;
  String get report;
  
  // Teachers
  String get teachersList;
  String get noTeachersAvailable;
  String get noTeachersForLanguage;
  String get selectPackage;
  String get selectDayTime;
  String get bookSession;
  String get sessionBooked;
  String get bookingFailed;
  String get availableSlots;
  String get noAvailableSlots;
  String get selectTimeSlot;
  String get teacherDetails;
  String get rating;
  String get reviews;
  String get about;
  String get experience;
  String get languages;
  String get hourlyRate;
  String get perSession;
  
  // Students
  String get studentsList;
  String get searchStudents;
  String get noStudentsFound;
  String get studentsWillAppearHere;
  String get sendChatRequest;
  String get chatRequestSent;
  String get alreadyChatting;
  
  // Packages
  String get packages;
  String get selectYourPackage;
  String get packageDetails;
  String get sessionsPerWeek;
  String get totalSessions;
  String get price;
  String get subscribe;
  String get subscriptionActive;
  String get subscriptionExpired;
  
  // Notifications
  String get notifications;
  String get notificationSettings;
  String get noNotifications;
  String get markAllRead;
  String get enableNotifications;
  String get sessionReminders;
  String get chatMessages;
  String get practiceReminders;
  // Notifications - additional
  String get allNotificationsMarkedRead;
  String get clearAllNotificationsTitle;
  String get clearAllNotificationsMessage;
  String get clearAllButton;
  String notificationsCleared(int count);
  String get readAll;
  String get clear;
  String get youreAllCaughtUp;
  
  // Days of week
  String get monday;
  String get tuesday;
  String get wednesday;
  String get thursday;
  String get friday;
  String get saturday;
  String get sunday;
  
  // Months
  String get january;
  String get february;
  String get march;
  String get april;
  String get may;
  String get june;
  String get july;
  String get august;
  String get september;
  String get october;
  String get november;
  String get december;
  
  // Error messages
  String get errorLoadingData;
  String get errorSavingData;
  String get errorNoInternet;
  String get errorTryAgain;
  String get errorUnknown;
  
  // Success messages
  String get successSaved;
  String get successUpdated;
  String get successDeleted;
  
  // Validation
  String get fieldRequired;
  String get invalidInput;
  String get tooShort;
  String get tooLong;
  
  // Settings screens
  String get aboutUsContent;
  String get privacyPolicyContent;
  String get termsConditionsContent;
  
  // Contact
  String get couldNotOpenWhatsApp;
  String get errorOpeningWhatsApp;
  
  // Province/City selection
  String get chooseCity;
  String get selectProvince;
  String get searchProvince;
  String get pleaseSelectProvince;
  String get fillAllFields;
  String get confirmAccount;
  
  // Teacher-specific
  String get specialization;
  String get specializationOptional;
  String get teacherAccount;
  String get dashboard;
  String get quickActions;
  String get schedule;
  String get sessions;
  String get languagesITeach;
  String get noLanguagesAssigned;
  String get upcomingSessions;
  String get meetingLink;
  String get setDefaultMeetingLink;
  String get meetingLinkWillBeUsed;
  String get studentsCanJoinUsingLink;
  String get meetingLinkUpdated;
  String get failedToUpdateMeetingLink;
  String get viewAllReviews;
  String get noReviewsYet;
  String get totalRatings;
  
  // Point Awards
  String get awardPointsToStudents;
  String get awardPointsTo;
  String get currentLevelLabel;
  String get currentPointsLabel;
  String get pointsAwardedByYou;
  String get pointLimits;
  String get selectPointsToAward;
  String get totalPoints;
  String youveAwardedPointsToThisStudent(int points);
  String get orEnterCustomAmount;
  String get pleaseEnterOrSelectPoints;
  String maxPointsPerAwardValidation(int max);
  String get addANote;
  String get whyIsStudentReceivingPoints;
  String get noteExample;
  String get pleaseAddNoteExplainingAward;
  String get maxPerAward;
  String get maxPerStudent;
  String get maxPerDay;
  String get maxPerWeek;
  String get pointsToAward;
  String get enterPoints;
  String get pleaseEnterPoints;
  String get enterValidPositiveNumber;
  String get maxPointsPerAward;
  String get note;
  String get whyAwardingPoints;
  String get explainWhyEarned;
  String get pleaseEnterNote;
  String get noteMinLength;
  String get awardPoints;
  String get pointsAwardedSuccessfully;
  String get newLevel;
  String get failedToAwardPoints;
  String get noStudentsEnrolled;
  String get levelLabel;
  String get awardedByYou;
  String get award;
  
  // Create Session
  String get createSession;
  String get selectStudent;
  String get noActiveSubscriptions;
  String get sessionSchedule;
  String get dateLabel;
  String get start;
  String get end;
  String get createSessionButton;
  String get selectStudentSubscription;
  String get endTimeMustBeAfterStart;
  String get sessionCreatedSuccessfully;
  String get errorCreatingSession;
  String get sessionsLeft;
  
  // Timeslot Management
  String get manageTimeslots;
  String get timeslotsOverview;
  String get total;
  String get available;
  String get disabled;
  String get booked;
  String get noTimeslotsYet;
  String get addScheduleToGenerate;
  String get availableLabel;
  String get bookedLabel;
  String get disabledLabel;
  String get enableAll;
  String get disableAll;
  String get cannotDisableOccupied;
  String get timeslotEnabledSuccessfully;
  String get timeslotDisabledSuccessfully;
  String get failedToUpdateTimeslot;
  String get noAvailableSlotsToToggle;
  String get timeslotsEnabled;
  String get timeslotsDisabled;
  
  // Schedule management
  String get myScheduleTitle;
  String get noScheduleSet;
  String get addYourAvailableTimeSlots;
  String get addTimeSlot;
  String get deleteScheduleTitle;
  String get deleteScheduleMessage;
  String get slotLabel;
  String get slotsLabel;
  String get dayOfWeekLabel;
  String get timeLabel;
  String get toLabel;
  
  // Common additional
  String get level;
  String levelDisplay(int level);
  String get pts;
  String awarded(int points);
  String get session;
  String get minute;
  String get minutesPlural;
  
  // Chat additional
  String get chatDeletedSuccessfully;
  String get failedToDeleteChat;
  String get messageUnsent;
  String get downloadedToUnableToOpen;
  
  // Classes additional
  String get errorLoadingSessions;
  String get errorJoiningSession;
  String get teacherInformationNotAvailable;
  String get unableToStartChat;
  String get errorOpeningChat;
  String get unableToLoadTeacherDetails;
  String get myClasses;
  String get noUpcomingClasses;
  String get noFinishedClasses;
  String get pullDownToRefresh;
  String get setMeetingLink;
  String get enterMeetingLinkHint;
  String get meetingLinkUpdatedSuccessfully;
  String get sessionStarted;
  String get endSessionTitle;
  String get endSessionMessage;
  String get sessionEndedSuccessfully;
  String get cancelSessionTitle;
  String get cancelSessionMessage;
  String get reasonOptional;
  String get enterCancellationReason;
  String get back;
  String get cancelledByTeacher;
  String get sessionCancelledSuccessfully;
  String get failedToCancelSession;
  String get deleteSessionTitle;
  String get deleteSessionMessage;
  String get deleteButton;
  String get sessionDeletedSuccessfully;
  String get failedToDeleteSessionOnly;
  String get pleaseSetMeetingLinkFirst;
  String get studentInformationNotAvailable;
  String get studentPlaceholder;
  String get today;
  String get makeupClass;
  String get manuallyCreated;
  String get languagePlaceholder;
  String get updateLink;
  String get setLink;
  String get joinButton;
  String get startButton;
  String get endButton;
  String get deleteSessionButton;
  String get cancelSessionButton;
  String get statusScheduled;
  String get statusReady;
  String get statusInProgress;
  String get statusCompleted;
  String get statusCancelled;
  String get statusMissed;
  String get min;
  String get mon;
  String get tue;
  String get wed;
  String get thu;
  String get fri;
  String get sat;
  String get sun;
  String get jan;
  String get feb;
  String get mar;
  String get apr;
  // may is already defined above in full months - same in short form
  String get jun;
  String get jul;
  String get aug;
  String get sep;
  String get oct;
  String get nov;
  String get dec;
  
  // Profile additional
  String get allReviews;
  String get logoutTitle;
  String get logoutConfirmMessage;
  String get logoutButton;
  String get logoutFailed;
  String get personalInformationSection;
  String get editProfileTitle;
  String get updateProfileInfo;
  String get securitySection;
  String get teacherPlaceholder;
  String get languageTeacher;
  
  // Profile page - additional
  String get profileTitle;
  String get aboutMe;
  String get accountInformation;
  String get notAvailable;
  String get memberSince;
  String get recentReviews;
  String get viewAll;
  String get updateYourPassword;
  String get logoutButtonText;
  String get defaultMeetingLink;
  String get editMeetingLinkTooltip;
  String get meetingLinkNotSet;
  String get setMeetingLinkMessage;
  
  // Chat file operations
  String get downloading;
  String get downloadFailed;
  String get failedToLoadImage;
  String get tapToRetry;
  
  // Chat list screen
  String get messagesTitle;
  String get searchMessages;
  String get showConversations;
  String get startNewChat;
  String get requestAccepted;
  String get failedToAcceptRequest;
  String get requestRejected;
  String get failedToRejectRequest;
  String get justNow;
  String minutesAgo(int minutes);
  String get oneDayAgo;
  String daysAgo(int days);
  String get noResultsFound;
  String get noMessagesYet;
  String get tryDifferentKeywords;
  String get startConversationWithStudents;
  String get chatRequestTitle;
  String get noMessageProvided;
  String get sentChatRequest;
  String get deleteChat;
  String get deleteChatQuestion;
  String deleteChatConfirmation(String name);
  String get noStudentsAvailable;
  String get waitForStudentsToSubscribe;
  String get imageAttachment;
  String get voiceMessage;
  String get fileAttachment;
  String get attachmentGeneric;
  String get startChatting;
  String get user;
  
  // Edit Profile
  String get chooseProfilePicture;
  String get chooseFromGallery;
  String get takeAPhoto;
  String get removePhoto;
  String errorPickingImage(String error);
  String get profileUpdatedSuccessfully;
  String failedToUpdateProfile(String error);
  String get enterYourFullName;
  String get pleaseEnterYourName;
  String get specializationExample;
  String get tellStudentsAboutYourself;
  String get introductionVideoYouTubeUrl;
  String get youtubeUrlHint;
  String get pleaseEnterValidYouTubeUrl;
  String get zoomGoogleMeetEtc;
  String get saveChanges;
  String get addPhoto;
  String get changePhoto;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'ar', 'es'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    switch (locale.languageCode) {
      case 'ar':
        return AppLocalizationsAr();
      case 'es':
        return AppLocalizationsEs();
      case 'en':
      default:
        return AppLocalizationsEn();
    }
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

