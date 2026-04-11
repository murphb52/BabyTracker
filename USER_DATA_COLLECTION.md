# BabyTracker User Data Collection

This document outlines all data collected from users in the BabyTracker application.

## 1. Child Profile Data

### Child Information
- **Child ID** (UUID) - Unique identifier for each child
- **Name** - Child's name
- **Birth Date** - Child's date of birth
- **Child Image** - Photo of the child (stored as data)
- **Preferred Feed Volume Unit** - User's preference for measuring bottle feeds (milliliters, ounces, etc.)
- **Archived Status** - Whether the child's profile is archived
- **Created At** (Date) - When the profile was created
- **Updated At** (Date) - When the profile was last updated
- **Created By** (User ID) - Which user created the profile
- **Last Synced At** (Date) - CloudKit sync timestamp
- **Sync State** - Current synchronization status
- **Last Sync Error Code** - Any error from last sync attempt

### CloudKit Sharing Data
- **CloudKit Zone Name** - iCloud private database zone
- **CloudKit Zone Owner Name** - Name of the zone owner
- **CloudKit Share Record Name** - Name of the shared record for access control

---

## 2. Event Data

All events include common metadata and event-specific data:

### Common Event Data (All Events)
- **Event ID** (UUID) - Unique identifier
- **Child ID** (UUID) - Associated child
- **Occurred At** (Date) - When the event happened
- **Created At** (Date) - When logged/created
- **Created By** (User ID) - Which user created the entry
- **Updated At** (Date) - Last modification timestamp
- **Updated By** (User ID) - Which user last updated
- **Notes** - Custom notes/comments
- **Deleted** - Soft delete flag
- **Deleted At** (Date) - When deleted
- **Sync State** - CloudKit sync status
- **Last Synced At** (Date) - CloudKit sync timestamp
- **Last Sync Error Code** - Sync error if any

### Breast Feeding Events
- **Side** - Which side (left, right, both)
- **Started At** (Date) - Session start time
- **Ended At** (Date) - Session end time
- **Left Duration** (seconds) - Duration on left side
- **Right Duration** (seconds) - Duration on right side

### Bottle Feeding Events
- **Amount** (milliliters) - Volume consumed
- **Milk Type** - Type of milk (formula, breast milk, etc.)

### Sleep Events
- **Started At** (Date) - Sleep start time
- **Ended At** (Date) - Sleep end time

### Nappy/Diaper Events
- **Type** - Diaper type (wet, dirty, both)
- **Intensity** - Severity level
- **Pee Volume** - Amount of pee
- **Poo Volume** - Amount of poo
- **Poo Color** - Color of stool (for health tracking)

---

## 3. User Identity Data

### User Profile
- **User ID** (UUID) - Unique identifier for each user
- **Display Name** - How the user is shown to others
- **Created At** (Date) - When user identity was created
- **CloudKit User Record Name** - iCloud authentication identifier
- **Sync State** - CloudKit sync status
- **Last Synced At** (Date) - CloudKit sync timestamp
- **Last Sync Error Code** - Sync error if any

---

## 4. Membership & Sharing Data

### Child Memberships (Who has access to which child)
- **Membership ID** (UUID) - Unique identifier
- **Child ID** (UUID) - Associated child
- **User ID** (UUID) - User who has access
- **Role** - Permission level (e.g., owner, editor, viewer)
- **Status** - Membership status (pending, accepted, rejected)
- **Invited At** (Date) - When the invite was sent
- **Accepted At** (Date) - When the invite was accepted
- **Sync State** - CloudKit sync status
- **Last Synced At** (Date) - CloudKit sync timestamp
- **Last Sync Error Code** - Sync error if any

---

## 5. CloudKit Sync & Internal Data

### Sync Management
- **Sync State** (per record) - Upload/download/pending status
- **Last Synced At** - Last successful sync timestamp
- **Last Sync Error Code** - Error code if sync failed
- **CloudKit Record Metadata** - iCloud database record references

---

## Data Collection Summary

### Categories
- **Child/Baby Information**: Names, birth dates, photos, preferences
- **Activity Tracking**: Feeding times/durations/amounts, sleep patterns, diaper statistics
- **User Management**: User display names, authentication IDs, role-based access
- **Health Information**: Sleep data, feeding data, diaper patterns (potentially sensitive health data)
- **Sharing/Collaboration**: Who has access to each child's data and their roles
- **Sync Metadata**: Timestamps and status for cloud synchronization

### Sensitive Data
- Birth dates
- Child photos
- Health-related information (feeding patterns, sleep, diaper changes)
- User identities and authentication information
- Access control and sharing information

### CloudKit Integration
All data is synced to Apple's CloudKit service for cross-device synchronization and sharing with other caregivers.
