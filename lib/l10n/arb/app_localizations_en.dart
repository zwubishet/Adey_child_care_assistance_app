// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get pageTitleNotificationDetail => 'Notification Details';

  @override
  String get messageLabel => 'Message';

  @override
  String deliveredLabel(Object date) {
    return 'Delivered: $date';
  }

  @override
  String get seenLabel => 'Seen';

  @override
  String get unreadLabel => 'Unread';

  @override
  String get relevanceLabel => 'Relevance';

  @override
  String get pageTitleNotificationHistory => 'Notification History';

  @override
  String get noNotifications => 'No notifications yet';

  @override
  String errorLabel(Object error) {
    return 'Error: $error';
  }

  @override
  String get pageTitleCommunity => 'Community';

  @override
  String get whatsOnYourMind => 'What\'s on your mind?';

  @override
  String get noPosts => 'No posts yet. Create a new one!';

  @override
  String get pageTitleProfile => 'Profile';

  @override
  String get languageSettings => 'Language Settings';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageAmharic => 'Amharic';

  @override
  String get viewNotification => 'View Notification';

  @override
  String get pageTitleHome => 'Home';

  @override
  String get pageTitleHealthMetrics => 'Health Metrics';

  @override
  String get pageTitleEducation => 'Education';

  @override
  String get pageTitleFavorites => 'Favorites';

  @override
  String get pageTitleWeeklyTip => 'Weekly Tip';

  @override
  String get pageTitleJournal => 'Journal';

  @override
  String greeting(String name) {
    return 'Hello, $name!';
  }

  @override
  String get pregnancyJourney => 'Pregnancy Journey';

  @override
  String get weeksLabel => 'Weeks';

  @override
  String get daysLabel => 'Days';

  @override
  String get weeklyTips => 'Weekly Tips';

  @override
  String get noTipsYet => 'No tips yet—add some!';

  @override
  String get exploreFeatures => 'Explore Features';

  @override
  String get featureCalendar => 'Calendar';

  @override
  String get featureCalendarDescription => 'Plan appointments';

  @override
  String get featureHealthMetrics => 'Health Metrics';

  @override
  String get featureHealthMetricsDescription => 'Track your health';

  @override
  String get featureJournal => 'Journal';

  @override
  String get featureJournalDescription => 'Write your thoughts';

  @override
  String get featureNameSuggestion => 'Name Suggestion';

  @override
  String get featureNameSuggestionDescription => 'Find baby names';

  @override
  String get noUserLoggedIn => 'No user logged in';

  @override
  String failedToLoadProfile(Object error) {
    return 'Failed to load profile: $error';
  }

  @override
  String weekLabel(Object week) {
    return 'Week';
  }

  @override
  String get noTitle => 'No Title';

  @override
  String get pageTitleHealthArticle => 'Health Article';

  @override
  String get noDiaryEntries => 'No diary entries yet';

  @override
  String errorLoadingEntries(Object error) {
    return 'Error loading entries: $error';
  }

  @override
  String get addedToFavorites => 'Added to favorites!';

  @override
  String get removedFromFavorites => 'Removed from favorites!';

  @override
  String errorUpdatingFavorite(Object error) {
    return 'Error updating favorite: $error';
  }

  @override
  String get noContent => 'No Content';

  @override
  String get moreButton => 'More >>>';

  @override
  String get lessButton => 'Less >>>';

  @override
  String postedAt(Object date) {
    return 'Posted at: $date';
  }

  @override
  String weekLabelWithNumber(int week) {
    return 'Week $week';
  }

  @override
  String get favoriteEntriesTitle => 'Favorite Entries';

  @override
  String get noFavoriteEntries => 'No favorite entries yet';

  @override
  String get refreshButton => 'Refresh';

  @override
  String get showMore => 'Show More >>>';

  @override
  String get showLess => 'Show Less >>>';

  @override
  String get postedAtLabel => 'Posted at';

  @override
  String get bottomNavHome => 'Home';

  @override
  String get bottomNavCommunity => 'Community';

  @override
  String get bottomNavEducation => 'Education';

  @override
  String get bottomNavConsult => 'Consult';

  @override
  String get failedToLoadUserData => 'Failed to load user data';

  @override
  String errorLoadingData(Object error) {
    return 'Error occurred: $error';
  }

  @override
  String get consultPageComingSoon => 'Consult Page (Coming Soon)';

  @override
  String get editProfileTitle => 'Edit Profile';

  @override
  String get chooseFromGallery => 'Choose from Gallery';

  @override
  String get takePhoto => 'Take Photo';

  @override
  String get personalInformation => 'Personal Information';

  @override
  String get fullNameLabel => 'Full Name';

  @override
  String get ageLabel => 'Age';

  @override
  String get weightLabel => 'Weight';

  @override
  String get heightLabel => 'Height';

  @override
  String get bloodPressureLabel => 'Blood Pressure (e.g., 120/80)';

  @override
  String get selectHealthConditions => 'Select applicable health conditions';

  @override
  String get describeHealthIssue => 'Describe your health issue';

  @override
  String get healthIssueHint => 'Describe your health background or issues here...';

  @override
  String get saveProfileButton => 'Save Profile';

  @override
  String failedToUpdateProfile(Object error) {
    return 'Failed to update profile: $error';
  }

  @override
  String get cameraPermissionDenied => 'Camera permission denied';

  @override
  String get galleryPermissionDenied => 'Gallery permission denied';

  @override
  String get imageTooLarge => 'Image is too large, please choose a smaller one';

  @override
  String errorPickingImage(Object error) {
    return 'Error picking image: $error';
  }

  @override
  String get profileUpdatedSuccessfully => 'Profile updated successfully!';

  @override
  String weightUnit(String unit) {
    String _temp0 = intl.Intl.selectLogic(
      unit,
      {
        'kg': 'kg',
        'lbs': 'lbs',
        'other': '$unit',
      },
    );
    return '$_temp0';
  }

  @override
  String heightUnit(String unit) {
    String _temp0 = intl.Intl.selectLogic(
      unit,
      {
        'cm': 'cm',
        'ft': 'ft',
        'other': '$unit',
      },
    );
    return '$_temp0';
  }

  @override
  String healthCondition(String condition) {
    String _temp0 = intl.Intl.selectLogic(
      condition,
      {
        'diabetes': 'Diabetes',
        'hypertension': 'Hypertension',
        'asthma': 'Asthma',
        'heartDisease': 'Heart Disease',
        'thyroidIssues': 'Thyroid Issues',
        'other': 'Other',
        'other': '$condition',
      },
    );
    return '$_temp0';
  }

  @override
  String errorMarkingAsSeen(Object error) {
    return 'Error marking as seen: $error';
  }

  @override
  String get tapToView => 'Tap to view';

  @override
  String get notificationChannelName => 'Daily Tip';

  @override
  String get notificationChannelDescription => 'Health tips every 4 days';

  @override
  String fallbackTipTitle(int index) {
    return 'Tip $index';
  }

  @override
  String get fallbackTipBody => 'Consult your doctor for advice.';

  @override
  String relevanceLabelWithValue(String value) {
    return 'Relevance: $value';
  }

  @override
  String get genderLabel => 'Gender';

  @override
  String get genderSelectionError => 'Please select a gender';

  @override
  String get enterHealthData => 'Enter Health Data';

  @override
  String get bpSystolicLabel => 'Blood Pressure Systolic (mmHg)';

  @override
  String get bpDiastolicLabel => 'Blood Pressure Diastolic (mmHg)';

  @override
  String get heartRateLabel => 'Heart Rate (BPM)';

  @override
  String get bodyTemperatureLabel => 'Body Temperature (°C)';

  @override
  String get weightLabelKg => 'Weight (kg)';

  @override
  String get saveDataButton => 'Save Data';

  @override
  String get recommendationsTitle => 'Recommendations';

  @override
  String get healthTrendsTitle => 'Health Trends';

  @override
  String get noDataAvailable => 'No data available';

  @override
  String get dataSavedSuccessfully => 'Data saved successfully!';

  @override
  String get failedToSaveData => 'Failed to save data. Please try again.';

  @override
  String get invalidValuesError => 'Please enter valid values for all fields';

  @override
  String get tempScaledLabel => 'Temperature (°C x 5)';

  @override
  String bpLowRecommendation(int bpSys, int bpDia) {
    return 'Your blood pressure appears low (Systolic: $bpSys mmHg, Diastolic: $bpDia mmHg). This could be due to dehydration, fatigue, or other factors. To stabilize, consider adding a small amount of salt (e.g., a pinch in your food), drinking more water throughout the day (aim for 8-10 glasses), and eating small, frequent meals. If you feel dizzy or faint often, consult a healthcare professional to rule out other issues.';
  }

  @override
  String bpHighRecommendation(int bpSys, int bpDia) {
    return 'Your blood pressure is elevated (Systolic: $bpSys mmHg, Diastolic: $bpDia mmHg), which may indicate hypertension. To manage, reduce salt intake by avoiding processed foods and choosing fresh ingredients, engage in moderate exercise like brisk walking or cycling for 30 minutes most days of the week, and practice stress reduction techniques like yoga or deep breathing for 10-15 minutes daily. If this persists across multiple readings, consider seeing a doctor for a detailed evaluation.';
  }

  @override
  String bpNormalRecommendation(int bpSys, int bpDia) {
    return 'Your blood pressure (Systolic: $bpSys mmHg, Diastolic: $bpDia mmHg) is within the normal range. To maintain this, continue a balanced diet rich in fruits, vegetables, and lean proteins, and get at least 150 minutes of moderate exercise per week. Monitoring trends over time helps ensure it stays stable.';
  }

  @override
  String hrLowRecommendation(int hr) {
    return 'Your heart rate ($hr BPM) is on the lower side. This can be normal for fit individuals, but if you\'re not highly active or feel unusually tired, it\'s worth monitoring. To boost cardiovascular health, include activities like jogging, swimming, or dancing a few times a week for 20-30 minutes. If your heart rate drops further or you experience symptoms like dizziness, consult a doctor.';
  }

  @override
  String hrHighRecommendation(int hr) {
    return 'Your heart rate ($hr BPM) is elevated, which could be due to stress, caffeine, or physical activity. To lower it, try relaxation techniques like deep breathing exercises (inhale for 4 seconds, exhale for 6 seconds) or meditation for 10-15 minutes daily. Limit stimulants like coffee or energy drinks, and ensure you\'re getting 7-9 hours of sleep. If consistently high, a medical evaluation may be needed.';
  }

  @override
  String hrNormalRecommendation(int hr) {
    return 'Your heart rate ($hr BPM) is in a healthy range. To maintain this, continue a regular schedule of moderate physical activities like walking or cycling and manage stress effectively with hobbies or relaxation practices. Keep monitoring to spot any unusual changes.';
  }

  @override
  String tempLowRecommendation(double temp) {
    return 'Your body temperature ($temp°C) is below average, which may indicate you\'re cold or your metabolism is sluggish. Keep warm by wearing layers or using a blanket, and consume warm beverages like herbal tea throughout the day. Monitor for signs of illness like fatigue or chills, and if this persists, consider consulting a doctor about a thyroid test, as low body temperature can sometimes indicate hormonal imbalances.';
  }

  @override
  String tempHighRecommendation(double temp) {
    return 'Your body temperature ($temp°C) is elevated, which may indicate a fever or overheating. Stay hydrated by drinking 8-12 glasses of water daily, rest in a cool environment, and avoid strenuous exercise until it subsides. If above 38°C or lasting more than a day, seek medical advice to rule out infections or other causes.';
  }

  @override
  String tempNormalRecommendation(double temp) {
    return 'Your body temperature ($temp°C) is normal. To maintain this, dress appropriately for the weather, stay hydrated with 6-8 glasses of water daily, and avoid extreme temperature changes. Regular monitoring helps catch any variations early.';
  }

  @override
  String weightLowRecommendation(double weight) {
    return 'Your weight ($weight kg) is on the lower side. To gain or maintain healthy weight, focus on a nutrient-dense diet with proteins like eggs, chicken, or beans, healthy fats like nuts or avocado, and complex carbs like whole grains. Aim for 3 balanced meals and 2 snacks daily, and consider light strength training exercises like small weight lifting to build muscle mass. If struggling to gain weight, consult a dietitian.';
  }

  @override
  String weightHighRecommendation(double weight) {
    return 'Your weight ($weight kg) is on the higher side. To manage, incorporate regular physical activity like walking, swimming, or yoga for 30-40 minutes most days of the week, and focus on a diet rich in vegetables, lean proteins, and whole grains while reducing sugary drinks and processed snacks. Set small, achievable goals (e.g., losing 0.5 kg per month) and track progress. A healthcare provider can offer tailored advice if needed.';
  }

  @override
  String weightNormalRecommendation(double weight) {
    return 'Your weight ($weight kg) is in a healthy range. To maintain this, continue a balanced diet filled with fruits, vegetables, and lean proteins, and get at least 150 minutes of moderate exercise per week. Regular weigh-ins help ensure consistency over time.';
  }

  @override
  String bpSysIncreasedRecommendation(int prevBpSys, int bpSys) {
    return 'Your systolic blood pressure has increased by more than 10 mmHg from your last measurement (from $prevBpSys to $bpSys). This could be due to situational factors (e.g., stress or diet), but monitor closely over the next few days. Reduce salt intake, avoid caffeine before bed, and try a 10-minute relaxation exercise daily to see if it stabilizes.';
  }

  @override
  String hrIncreasedRecommendation(int prevHr, int hr) {
    return 'Your heart rate has increased by more than 15 BPM compared to your previous entry (from $prevHr to $hr). This might reflect temporary stress or activity, but if you haven’t been exercising, consider what’s changed—too much coffee, poor sleep, or stress? Take time for a calming activity like reading or a warm bath to unwind.';
  }

  @override
  String weightIncreasedRecommendation(double prevWeight, double weight) {
    return 'Your weight has increased by more than 2 kg from your last record (from $prevWeight to $weight). This could be water retention or diet-related. Cut back on salty or carb-heavy meals for a few days and increase your water intake to flush out excess fluids. If persistent, reassess your calorie intake and activity level.';
  }

  @override
  String allVitalsNormalRecommendation(int bpSys, int bpDia, int hr, double temp, double weight) {
    return 'All your latest vitals (Blood Pressure: $bpSys/$bpDia mmHg, Heart Rate: $hr BPM, Temperature: $temp°C, Weight: $weight kg) are within normal ranges. Great job! Keep up your healthy habits, including a balanced diet, regular exercise (150 minutes per week), and consistent sleep (7-9 hours per night) to stay on track.';
  }

  @override
  String get noDataRecommendation => 'No data available yet. Start entering your health metrics to receive personalized recommendations.';

  @override
  String tooltipBpSys(int value) {
    return 'Blood Pressure Sys: $value mmHg';
  }

  @override
  String tooltipHr(int value) {
    return 'Heart Rate: $value BPM';
  }

  @override
  String tooltipTemp(double value) {
    return 'Temperature: $value°C';
  }

  @override
  String tooltipWeight(double value) {
    return 'Weight: $value kg';
  }

  @override
  String get boysLabel => 'Boys';

  @override
  String get femaleGender => 'Female';

  @override
  String get girlsLabel => 'Girls';

  @override
  String get maleGender => 'Male';

  @override
  String noNamesAvailable(String category) {
    return 'No names available for $category';
  }

  @override
  String get pageTitleNameSuggestion => 'Baby Name Suggestion';

  @override
  String get tabAll => 'All';

  @override
  String get tabChristian => 'Christian';

  @override
  String get tabMuslim => 'Muslim';

  @override
  String get addNoteLabel => 'Add Note';

  @override
  String get deleteAction => 'Delete';

  @override
  String errorDeletingNote(Object error) {
    return 'Error deleting note: $error';
  }

  @override
  String get loginPrompt => 'Please log in';

  @override
  String get noNotesMatchSearch => 'No notes match your search';

  @override
  String get noNotesYet => 'No notes yet. Add one!';

  @override
  String get searchHint => 'Search notes by title...';

  @override
  String get aboutSection => 'About';

  @override
  String get appointmentAccepted => 'Appointment Accepted';

  @override
  String get appointmentCancelled => 'Appointment Cancelled';

  @override
  String get appointmentCancelledMessage => 'This appointment has been cancelled. The video call will end.';

  @override
  String appointmentWithDoctor(String doctorName) {
    return 'Appointment with $doctorName';
  }

  @override
  String get appointmentsLabel => 'Appointments';

  @override
  String get availableDoctors => 'Available Doctors';

  @override
  String get availableTimeSlots => 'Available Time Slots';

  @override
  String get beforeJoining => 'Before Joining';

  @override
  String get bookAppointment => 'Book Appointment';

  @override
  String bookAppointmentWith(String fullName) {
    return 'Book Appointment with $fullName';
  }

  @override
  String get bookNewAppointmentTooltip => 'Book a new appointment';

  @override
  String get bookingLabel => 'Booking';

  @override
  String callEnded(Object error) {
    return 'Call ended: $error';
  }

  @override
  String get connectedToCall => 'Connected to call';

  @override
  String get connectedToServer => 'Connected to server';

  @override
  String get connectingToCall => 'Connecting to call...';

  @override
  String get contactInformation => 'Contact Information';

  @override
  String get copiedToClipboard => 'Copied to clipboard';

  @override
  String get copyLinkTooltip => 'Copy link';

  @override
  String get couldNotCreateProfile => 'Could not create user profile. Please try again.';

  @override
  String doctorProfile(String fullName, String speciality) {
    return 'Doctor Profile: $fullName, $speciality';
  }

  @override
  String doctorRating(String fullName, String speciality) {
    return 'Doctor $fullName, $speciality, 4.5 rating';
  }

  @override
  String get doctorsLabel => 'Doctors';

  @override
  String get emailLabel => 'Email Address';

  @override
  String get ensureStableConnection => 'Ensure you have a stable internet connection';

  @override
  String get errorJoiningCall => 'Error joining call';

  @override
  String get errorPrefix => 'Error';

  @override
  String errorSendingRequest(Object error) {
    return 'Error sending request: $error';
  }

  @override
  String get findQuietSpace => 'Find a quiet, private space for your consultation';

  @override
  String get haveQuestionsReady => 'Have your questions ready for the doctor';

  @override
  String get inCall => 'In call';

  @override
  String get invalidDateFormat => 'Invalid date format';

  @override
  String get joinNow => 'Join Now';

  @override
  String get joinVideoCall => 'Join Video Call';

  @override
  String get joining => 'Joining...';

  @override
  String get joiningCall => 'Joining call...';

  @override
  String get later => 'Later';

  @override
  String get meetingInformation => 'Meeting Information';

  @override
  String get motherAppTitle => 'Mothers App';

  @override
  String get navigateToAppointments => 'Navigate to Appointments page';

  @override
  String get navigateToBooking => 'Navigate to Booking page';

  @override
  String get navigateToDoctors => 'Navigate to Doctors page';

  @override
  String get newMeetingLinkAvailable => 'New meeting link available';

  @override
  String get newMeetingLinkMessage => 'A new video conference link is available. Would you like to join with the new link?';

  @override
  String get noAcceptedAppointments => 'No accepted appointments.\nAccepted appointments will appear here.';

  @override
  String get noAvailabilityFound => 'No availability found for this doctor.';

  @override
  String get noDateAvailable => 'No date available';

  @override
  String get noDescriptionAvailable => 'No description available';

  @override
  String get noDoctorsAvailable => 'No doctors available';

  @override
  String get noPendingAppointments => 'No pending appointments.\nRequests you send will appear here.';

  @override
  String get noRejectedAppointments => 'No rejected appointments.\nRejected appointments will appear here.';

  @override
  String get notAvailable => 'Not available';

  @override
  String get notConnected => 'Not connected - appointments may not be sent';

  @override
  String get notSpecified => 'Not specified';

  @override
  String get okLabel => 'OK';

  @override
  String get pageTitleAppointments => 'My Appointments';

  @override
  String get phoneLabel => 'Phone';

  @override
  String get pleaseSelectDateTime => 'Please select a date and time';

  @override
  String get ratingLabel => '4.5 (245 reviews)';

  @override
  String get readyToJoin => 'Ready to join';

  @override
  String get refreshAppointmentsTooltip => 'Refresh appointments';

  @override
  String get requestAppointment => 'Request Appointment';

  @override
  String get requestSent => 'Appointment request sent! The doctor\'s response will arrive soon.';

  @override
  String get rescheduleAppointment => 'Reschedule Appointment';

  @override
  String get selectDateTime => 'Select Date and Time';

  @override
  String specialityLabel(String speciality) {
    return 'Speciality: $speciality';
  }

  @override
  String get startCall => 'Start Call';

  @override
  String get startVideoCall => 'Start Video Call';

  @override
  String get statusAccepted => 'Accepted';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String get statusPending => 'Pending';

  @override
  String get statusRejected => 'Rejected';

  @override
  String timeZoneLabel(String timeZone) {
    return 'Time Zone: $timeZone';
  }

  @override
  String get upcomingAppointments => 'Upcoming Appointments';

  @override
  String get viewProfile => 'View Profile';

  @override
  String get waitingForDoctor => 'Waiting for the doctor...';

  @override
  String get yourMeetingLink => 'Your meeting link';

  @override
  String get retryButton => 'Retry';

  @override
  String get searchNotesHint => 'Search your notes...';

  @override
  String get pleaseLogIn => 'Please log in to continue';

  @override
  String get noteDeleted => 'Note deleted successfully';

  @override
  String get appName => 'Adde Assistance App';

  @override
  String get noInternetTitle => 'No Internet Connection';

  @override
  String get noInternetMessage => 'Please check your internet connection and try again.';

  @override
  String get genderFemale => 'Female';

  @override
  String get genderMale => 'Male';

  @override
  String get genderOther => 'Other';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get themeMode => 'Theme Mode';

  @override
  String consultationFee(Object amount) {
    return 'Consultation Fee: $amount ETB';
  }

  @override
  String get unknownName => 'Unknown Name';

  @override
  String get welcomeMessage => 'Welcome to the Adde Assistance App!';

  @override
  String get testCameraMic => 'Test your camera and microphone';

  @override
  String get yourDoctorWillJoin => 'Your doctor will join the meeting shortly';

  @override
  String roomName(Object roomName) {
    return 'Room: $roomName';
  }

  @override
  String statusLabel(Object status) {
    return 'Status: $status';
  }

  @override
  String scheduledFor(Object date) {
    return 'Scheduled for: $date';
  }

  @override
  String get videoConsultationTitle => 'Video Consultation';

  @override
  String get videoConsultationMessage => 'Your video consultation is ready to start.';

  @override
  String tabPending(int count) {
    return 'Pending ($count)';
  }

  @override
  String tabAccepted(int count) {
    return 'Accepted ($count)';
  }

  @override
  String tabRejected(int count) {
    return 'Rejected ($count)';
  }

  @override
  String statusPrefix(String status) {
    return 'Status: $status';
  }

  @override
  String get retryLabel => 'Retry';

  @override
  String errorFetchingUserData(String error) {
    return 'Error fetching user data: $error';
  }

  @override
  String errorFetchingComments(String error) {
    return 'Error fetching comments: $error';
  }

  @override
  String get commentCannotBeEmpty => 'Comment cannot be empty';

  @override
  String errorAddingComment(String error) {
    return 'Error adding comment: $error';
  }

  @override
  String get commentDeletedSuccessfully => 'Comment deleted successfully';

  @override
  String errorDeletingComment(String error) {
    return 'Error deleting comment: $error';
  }

  @override
  String get postDetailTitle => 'Post Details';

  @override
  String profileOf(String fullName) {
    return 'Profile of $fullName';
  }

  @override
  String likesCountText(int count) {
    return '$count likes';
  }

  @override
  String commentsCountText(int count) {
    return '$count comments';
  }

  @override
  String commentBy(String fullName) {
    return 'Comment by $fullName';
  }

  @override
  String deleteCommentBy(String fullName) {
    return 'Delete comment by $fullName';
  }

  @override
  String get noCommentsYet => 'No comments yet';

  @override
  String get writeCommentHint => 'Write a comment...';

  @override
  String get sendCommentTooltip => 'Send comment';

  @override
  String get unableToLoadChat => 'Unable to load chat';

  @override
  String get chatServiceUnavailable => 'Chat service is currently unavailable';

  @override
  String get pleaseLogInChat => 'Please log in to access chat';

  @override
  String databaseError(String message) {
    return 'Database error: $message';
  }

  @override
  String get networkError => 'Network error, please check your connection';

  @override
  String failedToSendMessage(String error) {
    return 'Failed to send message: $error';
  }

  @override
  String startChatting(String receiverName) {
    return 'Start chatting with $receiverName';
  }

  @override
  String get chatUnavailableHint => 'Chat is currently unavailable';

  @override
  String get typeMessageHint => 'Type a message...';

  @override
  String get sendMessageTooltip => 'Send message';

  @override
  String postBy(String fullName) {
    return 'Post by $fullName';
  }

  @override
  String get editPost => 'Edit Post';

  @override
  String get deletePost => 'Delete Post';

  @override
  String get unlikePost => 'Unlike post';

  @override
  String get likePost => 'Like post';

  @override
  String get commentOnPost => 'Comment on post';

  @override
  String get commentPost => 'Comment';

  @override
  String get imageSizeError => 'Image size exceeds 5MB limit';

  @override
  String get emptyContentError => 'Post content cannot be empty';

  @override
  String get userDataNotLoaded => 'User data not loaded, please try again';

  @override
  String errorSavingPost(String error) {
    return 'Error saving post: $error';
  }

  @override
  String get closeTooltip => 'Close';

  @override
  String get editPostTitle => 'Edit Post';

  @override
  String get postButton => 'Post';

  @override
  String get updateButton => 'Update';

  @override
  String get removeImageTooltip => 'Remove Image';

  @override
  String get addImageTooltip => 'Add Image';

  @override
  String get createPostTitle => 'Create Post';

  @override
  String errorFetchingUser(String error) {
    return 'Error fetching user: $error';
  }

  @override
  String get searchPosts => 'Search posts';

  @override
  String get createNewPost => 'Create a new post';

  @override
  String get welcomeBack => 'Welcome Back';

  @override
  String get passwordLabel => 'Password';

  @override
  String get forgetPassword => 'Forget password?';

  @override
  String get logIn => 'Log In';

  @override
  String get noAccount => 'Don\'t have an account?';

  @override
  String get register => 'Register';

  @override
  String get signInWithGoogle => 'Sign in with Google';

  @override
  String get emptyFieldsError => 'Please enter both email and password';

  @override
  String get loginFailedError => 'Login failed. Please try again';

  @override
  String get googleSignInCancelledError => 'Google Sign-In cancelled';

  @override
  String get googleSignInFailedError => 'Google Sign-In failed';

  @override
  String get googleAuthFailedError => 'Google authentication failed';

  @override
  String get invalidEmailError => 'Please enter a valid email address';

  @override
  String get invalidPasswordError => 'Password must be at least 6 characters';

  @override
  String get welcomeRegister => 'WELCOME';

  @override
  String get assistMessage => 'We Are Here, To Assist You!!!';

  @override
  String get confirmPasswordLabel => 'Confirm Password';

  @override
  String get signUpButton => 'Sign Up';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get loginLink => 'Login';

  @override
  String get signUpWithGoogle => 'Sign Up with Google';

  @override
  String get passwordsDoNotMatchError => 'Passwords do not match!';

  @override
  String get googleSignUpCancelledError => 'Google Sign-Up cancelled.';

  @override
  String get googleSignUpFailedError => 'Google Sign-Up failed. Please try again.';

  @override
  String get googleSignUpTokenError => 'Google Sign-Up Error: Missing tokens.';

  @override
  String get signUpFailedError => 'Signup failed. Please try again.';

  @override
  String get signUpSuccess => 'Signup successful!';

  @override
  String signUpError(Object error) {
    return 'Error: $error';
  }

  @override
  String get resetPasswordTitle => 'Reset Password';

  @override
  String get resetPasswordHeader => 'Reset Your Password';

  @override
  String get resetPasswordDescription => 'Enter your email to receive a reset link';

  @override
  String get resetLinkSentDescription => 'Check your email for the reset link';

  @override
  String get sendResetLinkButton => 'Send Reset Link';

  @override
  String get emailSentButton => 'Email Sent';

  @override
  String get emptyEmailError => 'Please enter your email address';

  @override
  String resetEmailSentSuccess(String email) {
    return 'Password reset email sent to $email';
  }

  @override
  String resetPasswordError(Object error) {
    return 'Error: $error';
  }

  @override
  String get welcomePageTitle1 => 'Adey Pregnancy And Child Care App';

  @override
  String get welcomePageContent1 => 'Welcome to Adey, your trusted partner for a safe and healthy pregnancy and child care journey.';

  @override
  String get welcomePageContent2 => 'Track your pregnancy and postpartum progress with tools that health status and give upgated recommedation.';

  @override
  String get welcomePageContent3 => 'Access educational resources on maternal health, including articles, weekly tips, and daily notification.';

  @override
  String get welcomePageContent4 => 'Connect with a community of users, share experiences, and receive support.';

  @override
  String get welcomePageContent5 => 'Use our chatbot for instant responses and guidance on pregnancy and child care queries.';

  @override
  String get skipButton => 'Skip';

  @override
  String get nextButton => 'Next';

  @override
  String get getStartedButton => 'Get Started';

  @override
  String get skipSemantics => 'Skip onboarding';

  @override
  String get nextSemantics => 'Next page';

  @override
  String get getStartedSemantics => 'Get started';

  @override
  String onboardingPageSemantics(int pageNumber) {
    return 'Onboarding page $pageNumber';
  }

  @override
  String get motherFormTitle => 'Welcome, Please Fill Below Form!';

  @override
  String get fullNameRequiredError => 'Full Name is required';

  @override
  String get selectGenderLabel => 'Select Gender';

  @override
  String get maleGenderOption => 'Male';

  @override
  String get femaleGenderOption => 'Female';

  @override
  String get selectAgeLabel => 'Select Your Age';

  @override
  String selectedAgeLabel(int age) {
    return 'Selected Age: $age';
  }

  @override
  String get enterHeightLabel => 'Enter Your Height';

  @override
  String get heightRequiredError => 'Height is required';

  @override
  String get heightInvalidError => 'Enter a valid number';

  @override
  String get bloodPressureRequiredError => 'Blood Pressure is required';

  @override
  String get bloodPressureInvalidError => 'Enter valid blood pressure (e.g., 120/80)';

  @override
  String get enterWeightLabel => 'Enter Your Weight';

  @override
  String get weightRequiredError => 'Weight is required';

  @override
  String get weightInvalidError => 'Enter a valid number';

  @override
  String get pregnancyStartDateLabel => 'Pregnancy Start Date';

  @override
  String get pregnancyStartDateNotSet => 'Not set';

  @override
  String get pregnancyStartDateQuestion => 'When Did You Become Pregnant?';

  @override
  String pregnancyDurationLabel(int weeks, int days) {
    return 'Pregnancy Duration: $weeks weeks and $days days';
  }

  @override
  String get healthConditionsLabel => 'Select Any Applicable Health Conditions';

  @override
  String get healthConditionDiabetes => 'Diabetes';

  @override
  String get healthConditionHypertension => 'Hypertension';

  @override
  String get healthConditionAsthma => 'Asthma';

  @override
  String get healthConditionHeartDisease => 'Heart Disease';

  @override
  String get healthConditionThyroidIssues => 'Thyroid Issues';

  @override
  String get healthConditionOther => 'Other';

  @override
  String get healthIssueDescriptionLabel => 'Describe Your Health Issue';

  @override
  String get submitButton => 'Submit';

  @override
  String get confirmSubmissionTitle => 'Confirm Submission';

  @override
  String get confirmSubmissionMessage => 'Are you sure you want to submit the form?';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get requiredFieldsError => 'Please fill all required fields!';

  @override
  String get invalidNumberError => 'Please enter valid numbers for weight and height!';

  @override
  String get formSubmitSuccess => 'Form submitted successfully!';

  @override
  String formSubmitError(Object error) {
    return 'Error submitting form: $error';
  }

  @override
  String get popupNotifications => 'Pop-up Notifications';

  @override
  String get availableHealthProfessionals => 'Available Health Professionals';

  @override
  String get nursesLabel => 'Nurses';

  @override
  String get noNursesAvailable => 'No nurses available at the moment';

  @override
  String get navigateToNurses => 'Navigate to nurses list';

  @override
  String get healthProfessionalsLabel => 'Health Professionals';

  @override
  String get navigateToHealthProfessionals => 'Navigate to health professionals list';

  @override
  String get selectHealthProfessionals => 'Select Health Professionals to view';

  @override
  String get viewComments => 'View Comments';

  @override
  String errorLikingPost(Object error) {
    return 'Error liking post: $error';
  }

  @override
  String errorSearchingPosts(Object error) {
    return 'Error searching posts: $error';
  }

  @override
  String errorFetchingPosts(Object error) {
    return 'Error fetching posts: $error';
  }

  @override
  String get messageButton => 'Message';

  @override
  String get postsTitle => 'Posts';

  @override
  String userAvatar(Object name) {
    return 'Avatar of $name';
  }

  @override
  String get sentMessage => 'Sent message';

  @override
  String get receivedMessage => 'Received message';

  @override
  String get emptyTitleError => 'Post title cannot be empty';

  @override
  String get postTitleHint => 'Enter post title';

  @override
  String get addCommentHint => 'Add a comment...';

  @override
  String get viewMessages => 'View Messages';

  @override
  String get messagesTitle => 'Messages';

  @override
  String get noMessages => 'No messages yet';

  @override
  String errorFetchingMessages(Object error) {
    return 'Error fetching messages: $error';
  }

  @override
  String errorFetchingConversations(Object error) {
    return 'Error fetching conversations: $error';
  }

  @override
  String get noConversations => 'No conversations yet';

  @override
  String get reportPostTitle => 'Report Post';

  @override
  String get reportPost => 'Report';

  @override
  String get reportReasonHint => 'reason for reporting';

  @override
  String get reportReasonRequired => 'Please provide a reason for reporting';

  @override
  String get reportSubmitted => 'Report submitted successfully';

  @override
  String errorReportingPost(Object error) {
    return 'Error reporting post: $error';
  }

  @override
  String get postOptions => 'Post options';

  @override
  String get reasonInappropriate => 'Inappropriate content';

  @override
  String get reasonSpam => 'Spam';

  @override
  String get reasonOffensive => 'Offensive language';

  @override
  String get reasonMisleading => 'Misleading information';

  @override
  String get reasonHarassment => 'Harassment or bullying';

  @override
  String get reasonCopyright => 'Copyright violation';

  @override
  String get reasonOther => 'Other';

  @override
  String get deletePostTitle => 'Delete Post';

  @override
  String get deletePostConfirmation => 'Are you sure you want to delete this post? This action cannot be undone.';

  @override
  String get deletePostSuccess => 'Post deleted successfully';

  @override
  String errorDeletingPost(Object error) {
    return 'Error deleting post: $error';
  }

  @override
  String get deleteButton => 'Delete';

  @override
  String get errorDeletingPostWithComments => 'Cannot delete post because it has comments.';

  @override
  String get you => 'You';

  @override
  String get imageMessage => 'Image';

  @override
  String get videoMessage => 'Video';

  @override
  String get documentMessage => 'Document';

  @override
  String get errorFetchingPost => 'Error fetching post: @error';

  @override
  String verificationCodeSentSuccess(Object email) {
    return 'Verification code sent to $email.';
  }

  @override
  String verificationCodeError(Object error) {
    return 'Failed to send or verify code: $error';
  }

  @override
  String get invalidCodeError => 'Please enter a valid 6-digit verification code.';

  @override
  String get emptyPasswordError => 'Please enter a new password.';

  @override
  String get passwordUpdateSuccess => 'Password updated successfully.';

  @override
  String get verificationCodeDescription => 'Enter the 6-digit verification code sent to your email and your new password.';

  @override
  String get passwordUpdateSuccessDescription => 'Your password has been updated successfully. You can now use it to sign in.';

  @override
  String get verificationCodeLabel => 'Verification Code';

  @override
  String get newPasswordLabel => 'New Password';

  @override
  String get verifyCodeButton => 'Verify Code & Update Password';

  @override
  String get sendVerificationCodeButton => 'Send Verification Code';

  @override
  String get passwordUpdatedButton => 'Password Updated';

  @override
  String get changePassword => 'Change Password';

  @override
  String get newPassword => 'New Password';

  @override
  String get confirmNewPassword => 'Confirm New Password';

  @override
  String get passwordTooShortError => 'Password must be at least 8 characters';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String passwordUpdateError(Object error) {
    return 'Failed to update password: $error';
  }

  @override
  String get submit => 'Submit';

  @override
  String errorLoggingOut(Object error) {
    return 'Failed to log out: $error';
  }

  @override
  String get enterOtpDescription => 'Enter the 6-digit code sent to your email and your new password.';

  @override
  String get otpLabel => '6-Digit Code';

  @override
  String get submitOtpButton => 'Submit';

  @override
  String get passwordUpdatedSuccess => 'Password updated successfully!';

  @override
  String get fullNameError => 'Please enter your full name';

  @override
  String get ageEmptyError => 'Please enter your age';

  @override
  String get ageInvalidError => 'Please enter a valid age (0-120)';

  @override
  String get weightEmptyError => 'Please enter your weight';

  @override
  String get heightEmptyError => 'Please enter your height';

  @override
  String get bloodPressureEmptyError => 'Please enter your blood pressure';

  @override
  String get pregnancyStartDateError => 'Please select your pregnancy start date';

  @override
  String get healthIssueEmptyError => 'Please describe your health issue';

  @override
  String get signInSuccess => 'Signed in successfully!';

  @override
  String get googleSignInConfigError => 'Google Sign-In configuration is missing';

  @override
  String get googleSignUpConfigError => 'Google Sign-Up configuration error';

  @override
  String get appointmentPayment => 'Appointment Payment';

  @override
  String get paymentRequired => 'Payment Required';

  @override
  String doctorName(Object name) {
    return 'Doctor: $name';
  }

  @override
  String get paymentAutoFillMessage => 'Your details will be automatically filled';

  @override
  String get initializingPayment => 'Initializing payment...';

  @override
  String get paymentInitializationFailed => 'Failed to initialize payment';

  @override
  String get checkPaymentStatus => 'Check Status';

  @override
  String get paymentSuccessful => 'Payment Successful!';

  @override
  String get paymentCompleted => 'Payment Completed';

  @override
  String get paymentSuccessMessage => 'Your payment has been processed successfully. You can now join the video consultation.';

  @override
  String get paymentProcessingMessage => 'Your payment is being processed. Please wait a moment.';

  @override
  String get payNow => 'Pay Now';

  @override
  String get paymentRequiredMessage => 'Payment is required before joining the video call';

  @override
  String get videoLinkPending => 'Video link will be available after payment';

  @override
  String get errorLoadingPaymentData => 'Error loading payment information';

  @override
  String get paymentStillPending => 'Payment is still pending';

  @override
  String get errorCheckingPayment => 'Error checking payment status';

  @override
  String get paid => 'Paid';

  @override
  String get unpaid => 'Payment Required';

  @override
  String get accepted => 'Accepted';

  @override
  String get pending => 'Pending';

  @override
  String get declined => 'Declined';

  @override
  String get unknown => 'Unknown';

  @override
  String get appointmentCompleted => 'Appointment completed';

  @override
  String get waitingForDoctorResponse => 'Waiting for doctor\'s response';

  @override
  String get appointmentDeclined => 'Appointment was declined';

  @override
  String get myAppointments => 'My Appointments';

  @override
  String get noAppointmentsScheduled => 'No appointments scheduled';

  @override
  String get unknownDoctor => 'Unknown Doctor';

  @override
  String get couldNotLaunchVideoCall => 'Could not launch video call';

  @override
  String get videoLinkNotAvailable => 'Video link not available';

  @override
  String get cancelLabel => 'Cancel';

  @override
  String get consultationsFee => 'Consultation Fee';

  @override
  String get typing => 'Typing...';

  @override
  String get online => 'Online';

  @override
  String lastSeen(Object time) {
    return 'Last seen $time';
  }

  @override
  String get sendImageTooltip => 'Send image';

  @override
  String get sendVoiceMessageTooltip => 'Send voice message';

  @override
  String get voiceMessagesNotSupported => 'Voice messages are not supported yet';

  @override
  String get messagePinned => 'Message pinned';

  @override
  String get messageUnpinned => 'Message unpinned';

  @override
  String errorPinningMessage(Object error) {
    return 'Failed to pin message: $error';
  }

  @override
  String errorUnpinningMessage(Object error) {
    return 'Failed to unpin message: $error';
  }

  @override
  String get pinMessage => 'Pin message';

  @override
  String get unpinMessage => 'Unpin message';

  @override
  String get replyMessage => 'Reply';

  @override
  String get copyMessage => 'Copy';

  @override
  String get messageCopied => 'Message copied';

  @override
  String get deleteMessage => 'Delete';

  @override
  String get messageDeleted => 'Message deleted';

  @override
  String errorDeletingMessage(Object error) {
    return 'Failed to delete message: $error';
  }

  @override
  String errorSendingImage(Object error) {
    return 'Failed to send image: $error';
  }

  @override
  String get viewChatActivity => 'View chat activity';

  @override
  String get chatActivity => 'Chat Activity';

  @override
  String get editMessage => 'Edit Message';

  @override
  String get failedToDeleteMessage => 'Failed to delete message: @error';

  @override
  String get editMessageHint => 'Edit your message...';

  @override
  String get cancelEdit => 'Cancel Edit';

  @override
  String get saveEdit => 'Save Edit';

  @override
  String get edited => 'Edited';

  @override
  String get refresh => 'Refresh';

  @override
  String get favorites => 'Favorites';

  @override
  String get removeFavorite => 'Remove from Favorites';

  @override
  String get addFavorite => 'Add to Favorites';

  @override
  String get errorTitle => 'Something Went Wrong';

  @override
  String get errorOnboardingMessage => 'Failed to load onboarding content.';

  @override
  String get errorRetryButton => 'Try Again';

  @override
  String get errorRegisterMessage => 'Failed to load registration page.';

  @override
  String get okButton => 'OK';

  @override
  String get successTitle => 'Success';

  @override
  String get emailNullError => 'Email is required';

  @override
  String errorCheckingNotifications(Object error) {
    return 'Failed to check notifications: $error';
  }

  @override
  String errorSchedulingTips(Object error) {
    return 'Failed to schedule health tips: $error';
  }

  @override
  String errorLoadingProfileImage(Object error) {
    return 'Failed to load profile image: $error';
  }
}
