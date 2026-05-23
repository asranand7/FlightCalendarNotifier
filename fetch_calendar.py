#!/usr/bin/env python3
import sys
import json
import argparse
import re
from Foundation import NSDate
from EventKit import EKEventStore

def get_meeting_platform(location, url, notes):
    loc_str = str(location or "").lower()
    url_str = str(url or "").lower()
    notes_str = str(notes or "").lower()
    
    if "meet.google.com" in url_str or "meet.google.com" in loc_str or "meet.google.com" in notes_str:
        return "Google Meet"
    elif "zoom.us" in url_str or "zoom.us" in loc_str or "zoom.us" in notes_str:
        return "Zoom"
    elif "teams.microsoft.com" in url_str or "teams.microsoft.com" in loc_str or "teams.microsoft.com" in notes_str:
        return "Teams"
    elif location:
        return location
    return None

def get_meeting_url(event):
    if event.URL():
        return event.URL().absoluteString()
    
    loc = event.location() or ""
    if loc.lower().startswith("http"):
        return loc
        
    notes = event.notes() or ""
    # Extract URLs from the notes description
    urls = re.findall(r'(https?://\S+)', notes)
    for u in urls:
        u_lower = u.lower()
        if "meet.google.com" in u_lower or "zoom.us" in u_lower or "teams.microsoft.com" in u_lower:
            # Clean up trailing punctuation if any
            return u.rstrip('.,;)')
    
    # Return first URL as a fallback if any URL exists
    if urls:
        return urls[0].rstrip('.,;)')
        
    return None

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--action', choices=['upcoming', 'next'], required=True)
    args = parser.parse_args()
    
    store = EKEventStore.alloc().init()
    now = NSDate.date()
    
    if args.action == 'upcoming':
        future = NSDate.dateWithTimeIntervalSinceNow_(45 * 60)
        predicate = store.predicateForEventsWithStartDate_endDate_calendars_(now, future, None)
        events = store.eventsMatchingPredicate_(predicate)
        
        result = []
        if events:
            for event in events:
                if event.isAllDay():
                    continue
                
                declined = False
                attendees = event.attendees()
                if attendees:
                    for attendee in attendees:
                        if attendee.isCurrentUser() and attendee.participantStatus() == 2:
                            declined = True
                            break
                if declined:
                    continue
                
                platform = get_meeting_platform(event.location(), event.URL(), event.notes())
                meeting_url = get_meeting_url(event)
                
                result.append({
                    "title": event.title() or "Untitled Meeting",
                    "startDate": event.startDate().timeIntervalSince1970(),
                    "endDate": event.endDate().timeIntervalSince1970(),
                    "eventIdentifier": event.eventIdentifier(),
                    "platform": platform,
                    "url": meeting_url
                })
        print(json.dumps(result))
        
    elif args.action == 'next':
        future = NSDate.dateWithTimeIntervalSinceNow_(24 * 60 * 60)
        predicate = store.predicateForEventsWithStartDate_endDate_calendars_(now, future, None)
        events = store.eventsMatchingPredicate_(predicate)
        
        result = []
        if events:
            for event in events:
                if event.isAllDay():
                    continue
                
                declined = False
                attendees = event.attendees()
                if attendees:
                    for attendee in attendees:
                        if attendee.isCurrentUser() and attendee.participantStatus() == 2:
                            declined = True
                            break
                if declined:
                    continue
                
                if event.startDate().timeIntervalSince1970() > now.timeIntervalSince1970():
                    platform = get_meeting_platform(event.location(), event.URL(), event.notes())
                    meeting_url = get_meeting_url(event)
                    result.append({
                        "title": event.title() or "Untitled Meeting",
                        "startDate": event.startDate().timeIntervalSince1970(),
                        "endDate": event.endDate().timeIntervalSince1970(),
                        "eventIdentifier": event.eventIdentifier(),
                        "platform": platform,
                        "url": meeting_url
                    })
            
            result.sort(key=lambda x: x["startDate"])
            
        if result:
            print(json.dumps(result[0]))
        else:
            print(json.dumps(None))

if __name__ == '__main__':
    main()
