//
//  Macro.h
//  DormCatChat
//
//  Created by Huang Jie on 1/21/15.
//  Copyright (c) 2015 Huang Jie. All rights reserved.
//

#ifndef DormCatChat_Macro_h
#define DormCatChat_Macro_h
#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]
#define INPUT_VIEW_HEIGHT 35
#define CHAT_BACKGROUND 0xecf1f4
#define SILVER_COLOR 0xbdc3c7
#define FLAT_GREEN 0x1d59c
#define FLAT_GRAY 0xECF0F1
#define FLAT_BLUE 0x6BB9F0
#define FLAT_PINK 0xead4b3
#define FLAT_ORANGE 0xe97f02
#define FLAT_YELLOW 0xffed2a
#define FLAT_RED 0xE26A6A
#define NAME @"Name"
#define EMAIL @"Email"
#define PHONE @"Phone"
#define ADDRESS @"Address"
#define AVENIR_LIGHT @"Avenir-Light"
#define AVENIR_BOLD @"Avenir-Bold"
#define CHATS_LIST @"chats_list"
#define AUTH_DATA @"AUTH_DATA"
#define FIREBASE_ROOT_URL @"https://dormcatchat.firebaseio.com"
#define ME @"me"
#define OTHER @"other"
#define UID @"UID"
#define CLEANER_INFO @"cleaner_info"
#define LONGITUDE @"longitude"
#define LATITUDE @"latitude"
#define LOCATION @"location"
#define AVERAGE_REVIEW_RATING @"average_review_rating"
#define MESSAGE_COUNT_PER_LOAD 10
#define DATE_FORMAT_STRING @"yyyy-MM-dd HH:mm:ss"
#define UNREAD_MESSAGE_COUNT_CHAT @"unreadMessageCountChat"
#define OWNER @"owner"
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#endif
