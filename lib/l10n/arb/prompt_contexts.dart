const Map<String, String> promptContexts = {
  'pageTitleNotificationDetail':
      'Translate "Notification Details" to Amharic for a mobile app, referring to a page showing details of a notification, using a clear and concise tone.',
  'messageLabel':
      'Translate "Message" to Amharic for a notification context in a mobile app, referring to the content of a notification, using a simple and neutral tone.',
  'deliveredLabel':
      'Translate "Delivered: {date}" to Amharic for a notification context, meaning the notification was sent at a specific date, preserving the {date} placeholder, using a concise tone.',
  'seenLabel':
      'Translate "Seen" to Amharic for a notification context, meaning "has been viewed" (e.g., a message or post), using a concise tone.',
  'unreadLabel':
      'Translate "Unread" to Amharic for a notification context, meaning "not yet viewed", using a concise tone.',
  'relevanceLabel':
      'Translate "Relevance" to Amharic for a notification ranking context, meaning "usefulness" or "importance", using a professional tone.',
  'pageTitleNotificationHistory':
      'Translate "Notification History" to Amharic for a mobile app, referring to a page showing past notifications, using a clear and concise tone.',
  'noNotifications':
      'Translate "No notifications yet" to Amharic for a mobile app, using a concise and natural tone (e.g., "yet no notifications").',
  'errorLabel':
      'Translate "Error: {error}" to Amharic for a mobile app, referring to a system error message, preserving the {error} placeholder, using a neutral tone.',
  'pageTitleCommunity':
      'Translate "Community" to Amharic for a pregnancy app, referring to a social feature where users can interact, using a friendly tone.',
  'whatsOnYourMind':
      'Translate "What\'s on your mind?" to Amharic for a social media app, using a neutral and friendly tone (e.g., "What are you thinking?").',
  'noPosts':
      'Translate "No posts available. Create one!" to Amharic for a social media app, using an informal and encouraging tone.',
  'pageTitleProfile':
      'Translate "Profile" to Amharic for a mobile app, referring to a user’s personal profile page, using a clear and concise tone.',
  'languageSettings':
      'Translate "Language Settings" to Amharic for a mobile app, referring to a settings page for selecting language, using a clear and professional tone.',
  'languageEnglish':
      'Translate "English" to Amharic for a language selection option in a mobile app, using the standard Amharic term for the English language.',
  'languageAmharic':
      'Translate "Amharic" to Amharic for a language selection option in a mobile app, using the standard Amharic term for the Amharic language.',
  'viewNotification':
      'Translate "View Notification" to Amharic for a mobile app, referring to an action to see a notification, using a concise and action-oriented tone.',
  'pageTitleHome':
      'Translate "Home" to Amharic for a mobile app, referring to the main landing page, using a simple and welcoming tone.',
  'pageTitleHealthMetrics':
      'Translate "Health Metrics" to Amharic for a pregnancy app, referring to health data like weight or blood pressure, using a clear and professional tone.',
  'pageTitleEducation':
      'Translate "Education" to Amharic for a pregnancy app, referring to educational content about pregnancy, using a concise and informative tone.',
  'pageTitleFavorites':
      'Translate "Favorites" to Amharic for a mobile app, referring to a page with user-saved items, using a friendly and concise tone.',
  'pageTitleWeeklyTip':
      'Translate "Weekly Tip" to Amharic for a pregnancy app, referring to weekly advice for pregnant users, using an encouraging and friendly tone.',
  'pageTitleJournal':
      'Translate "Journal" to Amharic for a personal diary or daily record in a mobile app, not a publication, using a personal and concise tone.',
  'greeting':
      'Translate "Hi, {name}!" to Amharic for a mobile app, referring to a greeting message on the home screen, using a friendly and welcoming tone.',
  'pregnancyJourney':
      'Translate "Pregnancy Journey" to Amharic for a mobile app, referring to a section title about pregnancy progress, using a clear and descriptive tone.',
  'weeksLabel':
      'Translate "Weeks" to Amharic for a mobile app, referring to a label for pregnancy duration in weeks, using a concise tone.',
  'daysLabel':
      'Translate "Days" to Amharic for a mobile app, referring to a label for pregnancy duration in days, using a concise tone.',
  'weeklyTips':
      'Translate "Weekly Tips" to Amharic for a mobile app, referring to a section title for weekly pregnancy tips, using a clear and informative tone.',
  'noTipsYet':
      'Translate "No tips yet—add some!" to Amharic for a mobile app, referring to a placeholder message when there are no weekly tips, using a friendly and encouraging tone.',
  'exploreFeatures':
      'Translate "Explore Features" to Amharic for a mobile app, referring to a section title for app features, using an engaging and inviting tone.',
  'featureCalendar':
      'Translate "Calendar" to Amharic for a mobile app, referring to a feature name for scheduling, using a concise tone.',
  'featureCalendarDescription':
      'Translate "Schedule Appointments" to Amharic for a mobile app, referring to a description of the calendar feature, using a clear and action-oriented tone.',
  'featureHealthMetrics':
      'Translate "Health Metrics" to Amharic for a mobile app, referring to a feature name for health tracking, using a concise tone.',
  'featureHealthMetricsDescription':
      'Translate "Check your health" to Amharic for a mobile app, referring to a description of the health metrics feature, using a clear and action-oriented tone.',
  'featureJournal':
      'Translate "Journal" to Amharic for a mobile app, referring to a feature name for writing notes, using a concise tone.',
  'featureJournalDescription':
      'Translate "Write your thoughts" to Amharic for a mobile app, referring to a description of the journal feature, using a clear and action-oriented tone.',
  'featureNameSuggestion':
      'Translate "Name Suggestion" to Amharic for a mobile app, referring to a feature name for suggesting baby names, using a concise tone.',
  'featureNameSuggestionDescription':
      'Translate "Find baby names" to Amharic for a mobile app, referring to a description of the name suggestion feature, using a clear and action-oriented tone.',
  'weekLabel':
      'Translate "Week" to Amharic for a mobile app, referring to a label for weekly tips, using a concise tone.',
  'noTitle':
      'Translate "No Title" to Amharic for a mobile app, referring to a placeholder for a missing title, using a concise tone.',
  'pageTitleHealthArticle':
      'Translate "Health Article" to Amharic for a mobile app, referring to a section title for educational health content, using a clear and descriptive tone.',
  'noDiaryEntries':
      'Translate "No diary entries yet." to Amharic for a mobile app, referring to a message shown when there are no educational articles, using a concise and neutral tone.',
  'errorLoadingEntries':
      'Translate "Error loading entries: {error}" to Amharic for a mobile app, referring to an error message when loading educational articles fails, using a clear and informative tone.',
  'addedToFavorites':
      'Translate "Added to favorites!" to Amharic for a mobile app, referring to a success message when an article is added to favorites, using a positive and concise tone.',
  'removedFromFavorites':
      'Translate "Removed from favorites!" to Amharic for a mobile app, referring to a success message when an article is removed from favorites, using a neutral and concise tone.',
  'errorUpdatingFavorite':
      'Translate "Error updating favorite: {error}" to Amharic for a mobile app, referring to an error message when updating the favorite status fails, using a clear and informative tone.',
  'noContent':
      'Translate "No Content" to Amharic for a mobile app, referring to a fallback text when an article has no content, using a concise and neutral tone.',
  'moreButton':
      'Translate "More >>>" to Amharic for a mobile app, referring to a button label to expand article content, using a concise and action-oriented tone.',
  'lessButton':
      'Translate "Less >>>" to Amharic for a mobile app, referring to a button label to collapse article content, using a concise and action-oriented tone.',
  'postedAt':
      'Translate "Posted At: {date}" to Amharic for a mobile app, referring to a label showing the posting date of an article, using a clear and descriptive tone.',
  'weekLabelWithNumber':
      'Translate "Week {week}" to Amharic for a mobile app, referring to a label for a weekly tip (e.g., "Week 1"), using a clear and descriptive tone.',
  'favoriteEntriesTitle':
      'Translate "Favorite Entries" to Amharic for a mobile app, referring to a page title for a section with user-saved items, using a friendly and concise tone.',
  'noFavoriteEntries':
      'Translate "No favorite entries yet." to Amharic for a mobile app, referring to a message shown when there are no favorite items, using a concise and neutral tone.',
  'refreshButton':
      'Translate "Refresh" to Amharic for a mobile app, referring to a button label to reload content, using a concise and action-oriented tone.',
  'showMore':
      'Translate "More >>>" to Amharic for a mobile app, referring to a button label to expand content, using a concise and action-oriented tone.',
  'showLess':
      'Translate "Less >>>" to Amharic for a mobile app, referring to a button label to collapse content, using a concise and action-oriented tone.',
  'postedAtLabel':
      'Translate "Posted At" to Amharic for a mobile app, referring to a label showing the posting date of an item, using a clear and descriptive tone.',
  'bottomNavHome':
      'Translate "Home" to Amharic for a mobile app, referring to a bottom navigation label for the main landing page, using a simple and welcoming tone.',
  'bottomNavCommunity':
      'Translate "Community" to Amharic for a mobile app, referring to a bottom navigation label for a social feature where users can interact, using a friendly tone.',
  'bottomNavEducation':
      'Translate "Education" to Amharic for a mobile app, referring to a bottom navigation label for educational content about pregnancy, using a concise and informative tone.',
  'bottomNavConsult':
      'Translate "Consult" to Amharic for a mobile app, referring to a bottom navigation label for a consultation feature, using a concise and professional tone.',
  'failedToLoadUserData':
      'Translate "Failed to load user data" to Amharic for a mobile app, referring to an error message when user data cannot be loaded, using a clear and concise tone.',
  'errorLoadingData':
      'Translate "An error occurred: {error}" to Amharic for a mobile app, referring to a system error message, preserving the {error} placeholder, using a neutral tone.',
  'consultPageComingSoon':
      'Translate "Consult Page (Coming Soon)" to Amharic for a mobile app, referring to a placeholder message for a feature that is not yet available, using a concise and neutral tone.',
  'editProfileTitle':
      'Translate "Edit Profile" to Amharic for a mobile app, referring to a page title for editing user profile information, using a clear and concise tone.',
  'chooseFromGallery':
      'Translate "Choose from Gallery" to Amharic for a mobile app, referring to an option to select a photo from the gallery, using a concise and action-oriented tone.',
  'takePhoto':
      'Translate "Take a Photo" to Amharic for a mobile app, referring to an option to capture a new photo, using a concise and action-oriented tone.',
  'personalInformation':
      'Translate "Personal Information" to Amharic for a mobile app, referring to a section title for user details, using a clear and descriptive tone.',
  'fullNameLabel':
      'Translate "Full Name" to Amharic for a mobile app, referring to a form label for the user\'s full name, using a concise tone.',
  'ageLabel':
      'Translate "Age" to Amharic for a mobile app, referring to a form label for the user\'s age, using a concise tone.',
  'weightLabel':
      'Translate "Weight" to Amharic for a mobile app, referring to a form label for the user\'s weight, using a concise tone.',
  'heightLabel':
      'Translate "Height" to Amharic for a mobile app, referring to a form label for the user\'s height, using a concise tone.',
  'bloodPressureLabel':
      'Translate "Blood Pressure (e.g., 120/80)" to Amharic for a mobile app, referring to a form label for blood pressure with an example, using a clear and descriptive tone.',
  'selectHealthConditions':
      'Translate "Select Applicable Health Conditions" to Amharic for a mobile app, referring to a section title for selecting health issues, using a clear and descriptive tone.',
  'describeHealthIssue':
      'Translate "Describe Your Health Issue" to Amharic for a mobile app, referring to a section title for describing a health condition, using a clear and descriptive tone.',
  'healthIssueHint':
      'Translate "Describe your health background or issues here..." to Amharic for a mobile app, referring to a placeholder text in a text field, using a neutral tone.',
  'saveProfileButton':
      'Translate "Save Profile" to Amharic for a mobile app, referring to a button label to save profile changes, using a concise and action-oriented tone.',
  'noUserLoggedIn':
      'Translate "No user logged in" to Amharic for a mobile app, referring to an error message when no user is logged in, using a clear and concise tone.',
  'failedToUpdateProfile':
      'Translate "Failed to update profile: {error}" to Amharic for a mobile app, referring to an error message when profile updating fails, preserving the {error} placeholder, using a clear and informative tone.',
  'cameraPermissionDenied':
      'Translate "Camera permission denied" to Amharic for a mobile app, referring to an error message when camera access is denied, using a clear and concise tone.',
  'galleryPermissionDenied':
      'Translate "Gallery permission denied" to Amharic for a mobile app, referring to an error message when gallery access is denied, using a clear and concise tone.',
  'imageTooLarge':
      'Translate "Image too large, please select a smaller one" to Amharic for a mobile app, referring to an error message when an image exceeds size limits, using a clear and informative tone.',
  'errorPickingImage':
      'Translate "Error picking image: {error}" to Amharic for a mobile app, referring to an error message when image selection fails, preserving the {error} placeholder, using a clear and informative tone.',
  'profileUpdatedSuccessfully':
      'Translate "Profile Updated Successfully!" to Amharic for a mobile app, referring to a success message when the profile is updated, using a positive and concise tone.',
  'weightUnit':
      'Translate the weight unit "{unit}" to Amharic for a mobile app, where "unit" can be "kg" or "lbs", using a concise tone.',
  'heightUnit':
      'Translate the height unit "{unit}" to Amharic for a mobile app, where "unit" can be "cm" or "ft", using a concise tone.',
  'healthCondition':
      'Translate the health condition "{condition}" to Amharic for a mobile app, where "condition" can be "diabetes", "hypertension", "asthma", "heartDisease", "thyroidIssues", or "other", using a clear and medical tone.',
  'errorMarkingAsSeen':
      'Translate "Error marking as seen: {error}" to Amharic for a mobile app, referring to an error when marking a notification as seen, preserving the {error} placeholder, using a neutral tone.',
  'tapToView':
      'Translate "Tap to view" to Amharic for a mobile app, referring to an action to view a notification by tapping, using a concise and action-oriented tone.',
  'notificationChannelName':
      'Translate "Daily Tip" to Amharic for a mobile app, referring to a notification channel name for daily health tips, using a concise and descriptive tone.',
  'notificationChannelDescription':
      'Translate "Health tips every 4 days" to Amharic for a mobile app, referring to a notification channel description for health tips sent every 4 days, using a clear and informative tone.',
  'fallbackTipTitle':
      'Translate "Tip {index}" to Amharic for a mobile app, referring to a fallback title for a health tip with an index number, preserving the {index} placeholder, using a concise tone.',
  'fallbackTipBody':
      'Translate "Consult your doctor for advice." to Amharic for a mobile app, referring to a fallback message in a health tip, using a professional and neutral tone.',
  'relevanceLabelWithValue':
      'Translate "Relevance: {value}" to Amharic for a mobile app, referring to a label showing the relevance score of a notification with a value placeholder, preserving the {value} placeholder, using a clear and descriptive tone.',
  'genderLabel':
      'Translate "Gender" to Amharic for a mobile app, referring to a label for selecting a user\'s gender, using a clear and descriptive tone.',
  'genderSelectionError':
      'Translate "Please select a gender" to Amharic for a mobile app, referring to a validation error message when a user does not select a gender, using a clear and instructive tone.',
  'enterHealthData':
      'Translate "Enter Health Data:" to Amharic for a mobile app, referring to a section title for inputting health metrics, using a clear and instructive tone.',
  'bpSystolicLabel':
      'Translate "BP Systolic (mmHg)" to Amharic for a mobile app, referring to a label for systolic blood pressure in millimeters of mercury, using a medical tone.',
  'bpDiastolicLabel':
      'Translate "BP Diastolic (mmHg)" to Amharic for a mobile app, referring to a label for diastolic blood pressure in millimeters of mercury, using a medical tone.',
  'heartRateLabel':
      'Translate "Heart Rate (bpm)" to Amharic for a mobile app, referring to a label for heart rate in beats per minute, using a medical tone.',
  'bodyTemperatureLabel':
      'Translate "Body Temperature (°C)" to Amharic for a mobile app, referring to a label for body temperature in Celsius, using a medical tone.',
  'weightLabelKg':
      'Translate "Weight (kg)" to Amharic for a mobile app, referring to a label for weight in kilograms, using a concise tone.',
  'saveDataButton':
      'Translate "Save Data" to Amharic for a mobile app, referring to a button to save health data, using a concise and action-oriented tone.',
  'recommendationsTitle':
      'Translate "Recommendations:" to Amharic for a mobile app, referring to a section title for health advice, using a clear and informative tone.',
  'healthTrendsTitle':
      'Translate "Health Trends:" to Amharic for a mobile app, referring to a section title for tracking health changes, using a clear and descriptive tone.',
  'noDataAvailable':
      'Translate "No data available." to Amharic for a mobile app, referring to a message when no health data exists, using a concise and neutral tone.',
  'dataSavedSuccessfully':
      'Translate "Data saved successfully!" to Amharic for a mobile app, referring to a success message after saving health data, using a positive and concise tone.',
  'failedToSaveData':
      'Translate "Failed to save data. Please try again." to Amharic for a mobile app, referring to an error message when saving fails, using a clear and instructive tone.',
  'invalidValuesError':
      'Translate "Please enter valid values for all fields." to Amharic for a mobile app, referring to a validation error, using a clear and instructive tone.',
  'tempScaledLabel':
      'Translate "Temp (°C x 5)" to Amharic for a mobile app, referring to a scaled temperature label for charting, using a technical tone.',
  'bpLowRecommendation':
      'Translate "Your blood pressure appears to be low (Systolic: {bpSys} mmHg, Diastolic: {bpDia} mmHg). This could be due to dehydration, fatigue, or other factors. To help stabilize it, consider increasing your salt intake slightly (e.g., adding a pinch to your meals), drinking more water throughout the day (aim for 8-10 glasses), and eating small, frequent meals to maintain energy levels. If you feel dizzy or faint often, consult a healthcare professional to rule out underlying issues." to Amharic for a mobile app, preserving {bpSys} and {bpDia} placeholders, using a clear and helpful tone.',
  'bpHighRecommendation':
      'Translate "Your blood pressure is elevated (Systolic: {bpSys} mmHg, Diastolic: {bpDia} mmHg), which might indicate hypertension. To manage this, reduce your salt intake by avoiding processed foods and opting for fresh ingredients, engage in moderate exercise like brisk walking or cycling for 30 minutes most days of the week, and practice stress-reduction techniques such as yoga or deep breathing for 10-15 minutes daily. If this persists across multiple readings, consider seeing a doctor for a detailed evaluation." to Amharic for a mobile app, preserving {bpSys} and {bpDia} placeholders, using a clear and helpful tone.',
  'bpNormalRecommendation':
      'Translate "Your blood pressure (Systolic: {bpSys} mmHg, Diastolic: {bpDia} mmHg) is within a normal range. To maintain this, continue a balanced diet rich in fruits, vegetables, and lean proteins, and keep up with regular physical activity (at least 150 minutes per week). Monitoring trends over time will help ensure it stays stable." to Amharic for a mobile app, preserving {bpSys} and {bpDia} placeholders, using a clear and encouraging tone.',
  'hrLowRecommendation':
      'Translate "Your heart rate ({hr} bpm) is on the lower side. This can be normal for fit individuals, but if you’re not highly active or feel unusually tired, it’s worth monitoring. Increase your physical activity with exercises like jogging, swimming, or dancing for 20-30 minutes a few times a week to boost cardiovascular health. Track this over time and consult a doctor if it drops further or you experience symptoms like lightheadedness." to Amharic for a mobile app, preserving {hr} placeholder, using a clear and helpful tone.',
  'hrHighRecommendation':
      'Translate "Your heart rate ({hr} bpm) is elevated, which could be due to stress, caffeine, or exertion. To bring it down, try relaxation techniques like deep breathing exercises (inhale for 4 seconds, exhale for 6) or meditation for 10-15 minutes daily. Limit stimulants like coffee or energy drinks, and ensure you’re getting 7-9 hours of sleep. If it remains high consistently, a medical checkup might be warranted." to Amharic for a mobile app, preserving {hr} placeholder, using a clear and helpful tone.',
  'hrNormalRecommendation':
      'Translate "Your heart rate ({hr} bpm) is in a healthy range. To keep it that way, maintain a routine of moderate exercise (e.g., walking or cycling) and ensure you’re managing stress effectively with hobbies or relaxation practices. Consistency is key—keep tracking it to spot any unusual changes." to Amharic for a mobile app, preserving {hr} placeholder, using a clear and encouraging tone.',
  'tempLowRecommendation':
      'Translate "Your body temperature ({temp}°C) is below average, which might suggest you’re cold or your metabolism is slow. Keep warm by layering clothing or using a blanket, and sip warm beverages like herbal tea throughout the day. Monitor for signs of illness like fatigue or chills, and if this persists, consider a thyroid check with your doctor since low temperature can sometimes indicate hormonal imbalances." to Amharic for a mobile app, preserving {temp} placeholder, using a clear and helpful tone.',
  'tempHighRecommendation':
      'Translate "Your body temperature ({temp}°C) is elevated, possibly indicating a fever or overheating. Stay hydrated by drinking 8-12 glasses of water daily, rest in a cool environment, and avoid heavy physical activity until it normalizes. If it exceeds 38°C or lasts more than a day, seek medical advice to rule out infections or other causes." to Amharic for a mobile app, preserving {temp} placeholder, using a clear and helpful tone.',
  'tempNormalRecommendation':
      'Translate "Your body temperature ({temp}°C) is normal. To maintain this, dress appropriately for the weather, stay hydrated with 6-8 glasses of water daily, and avoid extreme temperature changes. Regular monitoring will help you catch any deviations early." to Amharic for a mobile app, preserving {temp} placeholder, using a clear and encouraging tone.',
  'weightLowRecommendation':
      'Translate "Your weight ({weight} kg) is on the lower side. To gain or maintain a healthy weight, focus on a nutrient-dense diet including proteins (e.g., eggs, chicken, beans), healthy fats (e.g., nuts, avocados), and complex carbs (e.g., whole grains). Aim for 3 balanced meals and 2 snacks daily, and consider light strength training exercises like lifting small weights to build muscle mass. Consult a nutritionist if you’re struggling to gain weight." to Amharic for a mobile app, preserving {weight} placeholder, using a clear and helpful tone.',
  'weightHighRecommendation':
      'Translate "Your weight ({weight} kg) is on the higher side. To manage it, incorporate regular exercise like walking, swimming, or yoga for 30-40 minutes most days, and focus on a diet rich in vegetables, lean proteins, and whole grains while cutting back on sugary drinks and processed snacks. Set small, achievable goals (e.g., losing 0.5 kg per month) and track progress. A healthcare provider can offer tailored advice if needed." to Amharic for a mobile app, preserving {weight} placeholder, using a clear and helpful tone.',
  'weightNormalRecommendation':
      'Translate "Your weight ({weight} kg) is within a healthy range. To sustain this, continue eating a balanced diet with plenty of fruits, vegetables, and lean proteins, and stay active with at least 150 minutes of moderate exercise weekly. Regular weigh-ins will help you maintain consistency over time." to Amharic for a mobile app, preserving {weight} placeholder, using a clear and encouraging tone.',
  'bpSysIncreasedRecommendation':
      'Translate "Your systolic blood pressure has increased by more than 10 mmHg since your last reading (from {prevBpSys} to {bpSys}). This could be situational (e.g., stress or diet), but monitor it closely over the next few days. Reduce sodium intake, avoid caffeine close to bedtime, and try a 10-minute relaxation exercise daily to see if it stabilizes." to Amharic for a mobile app, preserving {prevBpSys} and {bpSys} placeholders, using a clear and helpful tone.',
  'hrIncreasedRecommendation':
      'Translate "Your heart rate has jumped by more than 15 bpm compared to your previous entry (from {prevHr} to {hr}). This might reflect temporary stress or activity, but if you haven’t been exercising, consider what’s changed—too much coffee, poor sleep, or anxiety? Take time to unwind with a calming activity like reading or a warm bath." to Amharic for a mobile app, preserving {prevHr} and {hr} placeholders, using a clear and helpful tone.',
  'weightIncreasedRecommendation':
      'Translate "Your weight has increased by more than 2 kg since your last record (from {prevWeight} to {weight}). This could be water retention or diet-related. Cut back on salty or carb-heavy meals for a few days and increase your water intake to flush out excess fluids. If it’s consistent, reassess your calorie intake and activity level." to Amharic for a mobile app, preserving {prevWeight} and {weight} placeholders, using a clear and helpful tone.',
  'allVitalsNormalRecommendation':
      'Translate "All your latest vitals (BP: {bpSys}/{bpDia} mmHg, HR: {hr} bpm, Temp: {temp}°C, Weight: {weight} kg) are within normal ranges. Great job! Keep up your healthy habits, including a balanced diet, regular exercise (150 minutes weekly), and consistent sleep (7-9 hours nightly) to stay on track." to Amharic for a mobile app, preserving {bpSys}, {bpDia}, {hr}, {temp}, and {weight} placeholders, using a clear and encouraging tone.',
  'noDataRecommendation':
      'Translate "No data available yet. Start by entering your health metrics to receive personalized recommendations." to Amharic for a mobile app, using a clear and encouraging tone.',
  'tooltipBpSys':
      'Translate "BP Sys: {value} mmHg" to Amharic for a mobile app, referring to a tooltip for systolic blood pressure with a value placeholder, using a medical tone.',
  'tooltipHr':
      'Translate "HR: {value} bpm" to Amharic for a mobile app, referring to a tooltip for heart rate with a value placeholder, using a medical tone.',
  'tooltipTemp':
      'Translate "Temp: {value}°C" to Amharic for a mobile app, referring to a tooltip for temperature with a value placeholder, using a medical tone.',
  'tooltipWeight':
      'Translate "Weight: {value} kg" to Amharic for a mobile app, referring to a tooltip for weight with a value placeholder, using a concise tone.',
  'boysLabel':
      'Translate "Boys" to Amharic for a mobile app, referring to a section label for baby boy names, using a concise tone.',
  'femaleGender':
      'Translate "Female gender" to Amharic for a mobile app, referring to an accessibility label for a female gender icon, using a clear and descriptive tone.',
  'girlsLabel':
      'Translate "Girls" to Amharic for a mobile app, referring to a section label for baby girl names, using a concise tone.',
  'maleGender':
      'Translate "Male gender" to Amharic for a mobile app, referring to an accessibility label for a male gender icon, using a clear and descriptive tone.',
  'noNamesAvailable':
      'Translate "No names available for {category}" to Amharic for a mobile app, referring to a message when no baby names are available for a category, preserving the {category} placeholder, using a neutral tone.',
  'pageTitleNameSuggestion':
      'Translate "Baby Name Suggester" to Amharic for a mobile app, referring to a page title for suggesting baby names, using a clear and descriptive tone.',
  'tabAll':
      'Translate "All" to Amharic for a mobile app, referring to a tab label for all baby names, using a concise tone.',
  'tabChristian':
      'Translate "Christian" to Amharic for a mobile app, referring to a tab label for Christian baby names, using the standard Amharic term for Christian.',
  'tabMuslim':
      'Translate "Muslim" to Amharic for a mobile app, referring to a tab label for Muslim baby names, using the standard Amharic term for Muslim.',
  'addNoteLabel':
      'Translate "Add Note" to Amharic for a mobile app, referring to an action to create a new journal note, using a concise and action-oriented tone.',
  'deleteAction':
      'Translate "Delete" to Amharic for a mobile app, referring to an action to remove a journal note, using a clear and action-oriented tone.',
  'errorDeletingNote':
      'Translate "Error deleting note: {error}" to Amharic for a mobile app, referring to an error message when deleting a note fails, preserving the {error} placeholder, using a neutral tone.',
  'loginPrompt':
      'Translate "Please log in" to Amharic for a mobile app, referring to a prompt when no user is logged in, using a polite and clear tone.',
  'noNotesMatchSearch':
      'Translate "No notes match your search" to Amharic for a mobile app, referring to a message when no journal notes match the search query, using a concise and neutral tone.',
  'noNotesYet':
      'Translate "No notes yet. Add one!" to Amharic for a mobile app, referring to a message when no journal notes exist, with an encouragement to add one, using a friendly tone.',
  'searchHint':
      'Translate "Search notes by title..." to Amharic for a mobile app, referring to a placeholder text in a search field for journal notes, using a clear and neutral tone.',
  'aboutSection':
      'Translate "About" to Amharic for a mobile app, referring to a section title about a doctor’s details, using a concise tone.',
  'appointmentAccepted':
      'Translate "Appointment Accepted" to Amharic for a mobile app, referring to a dialog title when an appointment is accepted, using a positive tone.',
  'appointmentCancelled':
      'Translate "Appointment Cancelled" to Amharic for a mobile app, referring to a dialog title when an appointment is cancelled, using a neutral tone.',
  'appointmentCancelledMessage':
      'Translate "This appointment has been cancelled. The video call will be ended." to Amharic for a mobile app, referring to a dialog message when an appointment is cancelled, using a neutral tone.',
  'appointmentWithDoctor':
      'Translate "Appointment with {doctorName}" to Amharic for a mobile app, referring to an appointment detail with a doctor, preserving the {doctorName} placeholder, using a neutral tone.',
  'appointmentsLabel':
      'Translate "Appointments" to Amharic for a mobile app, referring to a navigation label for appointments, using a concise tone.',
  'availableDoctors':
      'Translate "Available Doctors" to Amharic for a mobile app, referring to a page title for a list of doctors, using a descriptive tone.',
  'availableTimeSlots':
      'Translate "Available Time Slots:" to Amharic for a mobile app, referring to a label for available appointment times, using a concise tone.',
  'beforeJoining':
      'Translate "Before joining:" to Amharic for a mobile app, referring to a section title for video call instructions, using a concise tone.',
  'bookAppointment':
      'Translate "Book Appointment" to Amharic for a mobile app, referring to a button for booking an appointment, using an action-oriented tone.',
  'bookAppointmentWith':
      'Translate "Book appointment with {fullName}" to Amharic for a mobile app, referring to a semantics label for booking an appointment, preserving the {fullName} placeholder, using a descriptive tone.',
  'bookNewAppointmentTooltip':
      'Translate "Book New Appointment" to Amharic for a mobile app, referring to a tooltip for a button to book a new appointment, using a concise tone.',
  'bookingLabel':
      'Translate "Booking" to Amharic for a mobile app, referring to a navigation label for booking, using a concise tone.',
  'callEnded':
      'Translate "Call ended: {error}" to Amharic for a mobile app, referring to a call status when a video call ends, preserving the {error} placeholder, using a neutral tone.',
  'connectedToCall':
      'Translate "Connected to call" to Amharic for a mobile app, referring to a call status during a video consultation, using a positive tone.',
  'connectedToServer':
      'Translate "Connected to server" to Amharic for a mobile app, referring to a connection status message, using a positive tone.',
  'connectingToCall':
      'Translate "Connecting to call..." to Amharic for a mobile app, referring to a call status during a video consultation, using a neutral tone.',
  'contactInformation':
      'Translate "Contact Information" to Amharic for a mobile app, referring to a section title for a doctor’s contact details, using a descriptive tone.',
  'copiedToClipboard':
      'Translate "Copied to clipboard" to Amharic for a mobile app, referring to a message after copying a link, using a concise tone.',
  'copyLinkTooltip':
      'Translate "Copy link" to Amharic for a mobile app, referring to a tooltip for a button to copy a video call link, using a concise tone.',
  'couldNotCreateProfile':
      'Translate "Could not create user profile. Please try again." to Amharic for a mobile app, referring to an error message when creating a user profile fails, using a neutral tone.',
  'doctorProfile':
      'Translate "Doctor profile: {fullName}, {speciality}" to Amharic for a mobile app, referring to a semantics label for a doctor’s profile, preserving the {fullName} and {speciality} placeholders, using a descriptive tone.',
  'doctorRating':
      'Translate "Doctor {fullName}, {speciality}, 4.5 rating" to Amharic for a mobile app, referring to a semantics label for a doctor card, preserving the {fullName} and {speciality} placeholders, using a descriptive tone.',
  'doctorsLabel':
      'Translate "Doctors" to Amharic for a mobile app, referring to a navigation label for doctors, using a concise tone.',
  'emailLabel':
      'Translate "Email" to Amharic for a mobile app, referring to a label for a doctor’s email, using a concise tone.',
  'ensureStableConnection':
      'Translate "Ensure you have a stable internet connection" to Amharic for a mobile app, referring to a video call instruction, using a neutral tone.',
  'errorJoiningCall':
      'Translate "Error joining call" to Amharic for a mobile app, referring to a call status when joining a video call fails, using a neutral tone.',
  'errorPrefix':
      'Translate "Error:" to Amharic for a mobile app, referring to a prefix for error messages, using a concise tone.',
  'errorSendingRequest':
      'Translate "Error sending request: {error}" to Amharic for a mobile app, referring to an error message when sending an appointment request fails, preserving the {error} placeholder, using a neutral tone.',
  'findQuietSpace':
      'Translate "Find a quiet, private space for your consultation" to Amharic for a mobile app, referring to a video call instruction, using a neutral tone.',
  'haveQuestionsReady':
      'Translate "Have your questions ready for the doctor" to Amharic for a mobile app, referring to a video call instruction, using a neutral tone.',
  'inCall':
      'Translate "In Call" to Amharic for a mobile app, referring to a button label during a video call, using a concise tone.',
  'invalidDateFormat':
      'Translate "Invalid date format" to Amharic for a mobile app, referring to an error message for date formatting, using a neutral tone.',
  'joinNow':
      'Translate "Join Now" to Amharic for a mobile app, referring to a button to join a video call with a new link, using an action-oriented tone.',
  'joinVideoCall':
      'Translate "Join Video Call" to Amharic for a mobile app, referring to a button to join a video consultation, using an action-oriented tone.',
  'joining':
      'Translate "Joining..." to Amharic for a mobile app, referring to a button label while joining a video call, using a neutral tone.',
  'joiningCall':
      'Translate "Joining call..." to Amharic for a mobile app, referring to a call status during a video consultation, using a neutral tone.',
  'later':
      'Translate "Later" to Amharic for a mobile app, referring to a button to delay joining a video call, using a concise tone.',
  'meetingInformation':
      'Translate "Meeting Information" to Amharic for a mobile app, referring to a section title for video call details, using a descriptive tone.',
  'motherAppTitle':
      'Translate "Mother App" to Amharic for a mobile app, referring to a page title for the app, using a concise tone.',
  'navigateToAppointments':
      'Translate "Navigate to Appointments page" to Amharic for a mobile app, referring to a semantics label for navigation, using a descriptive tone.',
  'navigateToBooking':
      'Translate "Navigate to Booking page" to Amharic for a mobile app, referring to a semantics label for navigation, using a descriptive tone.',
  'navigateToDoctors':
      'Translate "Navigate to Doctors page" to Amharic for a mobile app, referring to a semantics label for navigation, using a descriptive tone.',
  'newMeetingLinkAvailable':
      'Translate "New Meeting Link Available" to Amharic for a mobile app, referring to a dialog title for a new video call link, using a neutral tone.',
  'newMeetingLinkMessage':
      'Translate "A new video conference link is available. Would you like to join with the new link?" to Amharic for a mobile app, referring to a dialog message for a new video call link, using a neutral tone.',
  'noAcceptedAppointments':
      'Translate "No accepted appointments.\nAccepted appointments will appear here." to Amharic for a mobile app, referring to an empty state message for accepted appointments, using a neutral tone.',
  'noAvailabilityFound':
      'Translate "No availability found for this doctor." to Amharic for a mobile app, referring to an error message when no availability is found, using a neutral tone.',
  'noDateAvailable':
      'Translate "No date available" to Amharic for a mobile app, referring to a message when no appointment date is available, using a neutral tone.',
  'noDescriptionAvailable':
      'Translate "No description available" to Amharic for a mobile app, referring to a fallback message for a doctor’s description, using a neutral tone.',
  'noDoctorsAvailable':
      'Translate "No doctors available" to Amharic for a mobile app, referring to an empty state message for doctors, using a neutral tone.',
  'noPendingAppointments':
      'Translate "No pending appointments.\nRequests you send will appear here." to Amharic for a mobile app, referring to an empty state message for pending appointments, using a neutral tone.',
  'noRejectedAppointments':
      'Translate "No rejected appointments.\nRejected appointments will appear here." to Amharic for a mobile app, referring to an empty state message for rejected appointments, using a neutral tone.',
  'notAvailable':
      'Translate "Not available" to Amharic for a mobile app, referring to a fallback message for a doctor’s phone number, using a neutral tone.',
  'notConnected':
      'Translate "Not connected - appointments may not be sent" to Amharic for a mobile app, referring to a connection status message, using a neutral tone.',
  'notSpecified':
      'Translate "Not specified" to Amharic for a mobile app, referring to a fallback message for a date, using a neutral tone.',
  'okLabel':
      'Translate "OK" to Amharic for a mobile app, referring to a dialog button, using a concise tone.',
  'pageTitleAppointments':
      'Translate "My Appointments" to Amharic for a mobile app, referring to a page title for appointments, using a descriptive tone.',
  'phoneLabel':
      'Translate "Phone" to Amharic for a mobile app, referring to a label for a doctor’s phone number, using a concise tone.',
  'pleaseSelectDateTime':
      'Translate "Please select a date and time" to Amharic for a mobile app, referring to an error message when a date and time are not selected, using a neutral tone.',
  'ratingLabel':
      'Translate "4.5 (245 reviews)" to Amharic for a mobile app, referring to a hardcoded doctor rating, using a neutral tone.',
  'readyToJoin':
      'Translate "Ready to join" to Amharic for a mobile app, referring to a call status before joining a video consultation, using a neutral tone.',
  'refreshAppointmentsTooltip':
      'Translate "Refresh appointments" to Amharic for a mobile app, referring to a tooltip for a refresh button, using a concise tone.',
  'requestAppointment':
      'Translate "Request Appointment" to Amharic for a mobile app, referring to a button to request an appointment, using an action-oriented tone.',
  'requestSent':
      'Translate "Appointment request sent! Waiting for doctor approval." to Amharic for a mobile app, referring to a success message after sending an appointment request, using a positive tone.',
  'retryLabel':
      'Translate "Retry" to Amharic for a mobile app, referring to a button to retry a connection, using a concise tone.',
  'roomName':
      'Translate "Room name: {roomName}" to Amharic for a mobile app, referring to a video call room name, preserving the {roomName} placeholder, using a neutral tone.',
  'scheduledFor':
      'Translate "Scheduled for: {date}" to Amharic for a mobile app, referring to an appointment date detail, preserving the {date} placeholder, using a neutral tone.',
  'statusLabel':
      'Translate "Status: {status}" to Amharic for a mobile app, referring to an appointment status in a video consultation, preserving the {status} placeholder, using a neutral tone.',
  'statusPrefix':
      'Translate "Status: {status}" to Amharic for a mobile app, referring to a connection status prefix, preserving the {status} placeholder, using a neutral tone.',
  'tabAccepted':
      'Translate "Accepted ({count})" to Amharic for a mobile app, referring to a tab label for accepted appointments, preserving the {count} placeholder, using a concise tone.',
  'tabPending':
      'Translate "Pending ({count})" to Amharic for a mobile app, referring to a tab label for pending appointments, preserving the {count} placeholder, using a concise tone.',
  'tabRejected':
      'Translate "Rejected ({count})" to Amharic for a mobile app, referring to a tab label for rejected appointments, preserving the {count} placeholder, using a concise tone.',
  'testCameraMic':
      'Translate "Test your camera and microphone" to Amharic for a mobile app, referring to a video call instruction, using a neutral tone.',
  'videoConsultationMessage':
      'Translate "Your appointment has been accepted! The video consultation will open shortly." to Amharic for a mobile app, referring to a dialog message when an appointment is accepted, using a positive tone.',
  'videoConsultationTitle':
      'Translate "Video Consultation" to Amharic for a mobile app, referring to a page title for a video consultation, using a descriptive tone.',
  'welcomeMessage':
      'Translate "Welcome to the Mother App!" to Amharic for a mobile app, referring to a welcome message, using a friendly tone.',
  'yourDoctorWillJoin':
      'Translate "Your doctor will use this same link to join the meeting." to Amharic for a mobile app, referring to a video call instruction, using a neutral tone.',
  'consultationFee':
      'Translate "Consultation Fee" to Amharic for a mobile app, referring to a label for a doctor’s consultation fee, using a concise tone.',
  'createNewPost':
      'Translate "Create a new post" to Amharic for a social media app, referring to a button action to create a new post, using a concise and action-oriented tone.',
  'searchPosts':
      'Translate "Search posts" to Amharic for a social media app, referring to a tooltip for a search icon, using a concise and action-oriented tone.',
  'errorFetchingUser':
      'Translate "Error fetching user: {error}" to Amharic for a mobile app, referring to an error message when fetching user data fails, preserving the {error} placeholder, using a neutral and informative tone.',
  'failedToLoadProfile':
      'Translate "Failed to load profile: {error}" to Amharic for a mobile app, referring to an error message when profile loading fails, preserving the {error} placeholder, using a clear and informative tone.',
  'genderFemale':
      'Translate "Female" to Amharic for a mobile app, referring to a gender option label, using a neutral and standard term for "Female".',
  'genderMale':
      'Translate "Male" to Amharic for a mobile app, referring to a gender option label, using a neutral and standard term for "Male".',
  'genderOther':
      'Translate "Other" to Amharic for a mobile app, referring to a gender option label, using a neutral and inclusive term for "Other".',
  'searchNotesHint':
      'Translate "Search your notes..." to Amharic for a mobile app search bar placeholder, using a concise and neutral tone.',
  'pleaseLogIn':
      'Translate "Please log in to continue" to Amharic for an error message prompting the user to log in, using a polite and clear tone.',
  'noteDeleted':
      'Translate "Note deleted successfully" to Amharic for a confirmation message when a note is deleted, using a positive and concise tone.',
  'retryButton':
      'Translate "Retry" to Amharic for a button label to retry an action, using a short and actionable tone.',
  'appName':
      'Translate "Adde Assistance App" to Amharic for a mobile app, referring to the application name displayed on the splash screen, using a clear and professional tone.',
  'noInternetTitle':
      'Translate "No Internet Connection" to Amharic for a mobile app, referring to the title of a dialog shown when there is no internet connection, using a clear and concise tone.',
  'noInternetMessage':
      'Translate "Please check your internet connection and try again." to Amharic for a mobile app, referring to a message in a dialog when there is no internet connection, using a polite and instructive tone.',
  'editProfile':
      'Translate "Edit Profile" to Amharic for a mobile app, referring to the option to edit the user profile, using a clear and concise tone.',
  'themeMode':
      'Translate "Theme Mode" to Amharic for a mobile app, referring to a label for the theme mode toggle (light/dark), using a clear and descriptive tone.',
  'unknownName':
      'Translate "Unknown Name" to Amharic for a mobile app, referring to a fallback text when a doctor\'s name is not available, using a clear and neutral tone.',
  'errorFetchingUserData':
      'Translate "Error fetching user data: {error}" to Amharic for a mobile app, referring to an error message shown when fetching user data fails, using a clear and descriptive tone.',
  'errorFetchingComments':
      'Translate "Error fetching comments: {error}" to Amharic for a mobile app, referring to an error message shown when fetching comments fails, using a clear and descriptive tone.',
  'commentCannotBeEmpty':
      'Translate "Comment cannot be empty" to Amharic for a mobile app, referring to an error message shown when a comment is empty or user is not logged in, using a clear and informative tone.',
  'errorAddingComment':
      'Translate "Error adding comment: {error}" to Amharic for a mobile app, referring to an error message shown when adding a comment fails, using a clear and descriptive tone.',
  'commentDeletedSuccessfully':
      'Translate "Comment deleted successfully" to Amharic for a mobile app, referring to a success message shown when a comment is deleted, using a clear and positive tone.',
  'errorDeletingComment':
      'Translate "Error deleting comment: {error}" to Amharic for a mobile app, referring to an error message shown when deleting a comment fails, using a clear and descriptive tone.',
  'postDetailTitle':
      'Translate "Post Details" to Amharic for a mobile app, referring to the title for the post detail screen, using a clear and professional tone.',
  'profileOf':
      'Translate "Profile of {fullName}" to Amharic for a mobile app, referring to an accessibility label for the profile avatar of the post author, using a clear and descriptive tone.',
  'likesCountText':
      'Translate "{count} likes" to Amharic for a mobile app, referring to text displaying the number of likes for a post, using a clear and concise tone.',
  'commentsCountText':
      'Translate "{count} comments" to Amharic for a mobile app, referring to text displaying the number of comments for a post, using a clear and concise tone.',
  'commentBy':
      'Translate "Comment by {fullName}" to Amharic for a mobile app, referring to an accessibility label for a comment by a specific user, using a clear and descriptive tone.',
  'deleteCommentBy':
      'Translate "Delete comment by {fullName}" to Amharic for a mobile app, referring to an accessibility label for the delete button of a comment by a specific user, using a clear and descriptive tone.',
  'noCommentsYet':
      'Translate "No comments yet" to Amharic for a mobile app, referring to a message shown when there are no comments on a post, using a clear and neutral tone.',
  'writeCommentHint':
      'Translate "Write a comment..." to Amharic for a mobile app, referring to hint text for the comment input field, using a clear and inviting tone.',
  'sendCommentTooltip':
      'Translate "Send comment" to Amharic for a mobile app, referring to a tooltip for the send comment button, using a clear and action-oriented tone.',
  'unableToLoadChat':
      'Translate "Unable to load chat" to Amharic for a mobile app, referring to an error message shown when the chat fails to load, using a clear and informative tone.',
  'chatServiceUnavailable':
      'Translate "Chat service is currently unavailable" to Amharic for a mobile app, referring to an error message shown when the chat database table is not found, using a clear and informative tone.',
  'pleaseLogInChat':
      'Translate "Please log in to access chat" to Amharic for a mobile app, referring to an error message shown when the user is not authenticated for chat, using a clear and polite tone.',
  'databaseError':
      'Translate "Database error: {message}" to Amharic for a mobile app, referring to an error message for database-related issues, using a clear and descriptive tone.',
  'networkError':
      'Translate "Network error, please check your connection" to Amharic for a mobile app, referring to an error message shown when a network issue occurs, using a clear and informative tone.',
  'failedToSendMessage':
      'Translate "Failed to send message: {error}" to Amharic for a mobile app, referring to an error message shown when sending a message fails, using a clear and descriptive tone.',
  'startChatting':
      'Translate "Start chatting with {receiverName}" to Amharic for a mobile app, referring to a message shown when there are no messages in the chat, using a clear and inviting tone.',
  'chatUnavailableHint':
      'Translate "Chat is currently unavailable" to Amharic for a mobile app, referring to hint text for the message input field when chat is unavailable, using a clear and informative tone.',
  'typeMessageHint':
      'Translate "Type a message..." to Amharic for a mobile app, referring to hint text for the message input field, using a clear and inviting tone.',
  'sendMessageTooltip':
      'Translate "Send message" to Amharic for a mobile app, referring to a tooltip for the send message button, using a clear and action-oriented tone.',
  'postBy':
      'Translate "Post by {fullName}" to Amharic for a mobile app, referring to an accessibility label for a post by a specific user, using a clear and descriptive tone.',
  'editPost':
      'Translate "Edit Post" to Amharic for a mobile app, referring to a label for the edit post option in a popup menu, using a clear and action-oriented tone.',
  'deletePost':
      'Translate "Delete Post" to Amharic for a mobile app, referring to a label for the delete post option in a popup menu, using a clear and action-oriented tone.',
  'unlikePost':
      'Translate "Unlike post" to Amharic for a mobile app, referring to an accessibility label for unliking a post, using a clear and descriptive tone.',
  'likePost':
      'Translate "Like post" to Amharic for a mobile app, referring to an accessibility label for liking a post, using a clear and descriptive tone.',
  'commentOnPost':
      'Translate "Comment on post" to Amharic for a mobile app, referring to an accessibility label for commenting on a post, using a clear and descriptive tone.',
  'commentPost':
      'Translate "Comment" to Amharic for a mobile app, referring to a label for the comment button on a post, using a clear and action-oriented tone.',
  'imageSizeError':
      'Translate "Image size exceeds 5MB limit" to Amharic for a mobile app, referring to an error message shown when the selected image is too large, using a clear and informative tone.',
  'emptyContentError':
      'Translate "Post content cannot be empty" to Amharic for a mobile app, referring to an error message shown when the post content is empty, using a clear and informative tone.',
  'userDataNotLoaded':
      'Translate "User data not loaded, please try again" to Amharic for a mobile app, referring to an error message shown when user data fails to load, using a clear and informative tone.',
  'errorSavingPost':
      'Translate "Error saving post: {error}" to Amharic for a mobile app, referring to an error message shown when saving a post fails, using a clear and descriptive tone.',
  'closeTooltip':
      'Translate "Close" to Amharic for a mobile app, referring to a tooltip for the close button, using a clear and action-oriented tone.',
  'editPostTitle':
      'Translate "Edit Post" to Amharic for a mobile app, referring to the title for the edit post screen, using a clear and descriptive tone.',
  'postButton':
      'Translate "Post" to Amharic for a mobile app, referring to a label for the post button when creating a new post, using a clear and action-oriented tone.',
  'updateButton':
      'Translate "Update" to Amharic for a mobile app, referring to a label for the update button when editing a post, using a clear and action-oriented tone.',
  'removeImageTooltip':
      'Translate "Remove Image" to Amharic for a mobile app, referring to a tooltip for the remove image button, using a clear and action-oriented tone.',
  'addImageTooltip':
      'Translate "Add Image" to Amharic for a mobile app, referring to a tooltip for the add image button, using a clear and action-oriented tone.',
  'createPostTitle':
      'Translate "Create Post" to Amharic for a mobile app, referring to the title for the create post screen, using a clear and descriptive tone.',
};
