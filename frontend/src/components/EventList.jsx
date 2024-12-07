import React, { useState } from 'react';
import { Filter, MapPin, Calendar, Tag } from 'lucide-react';

const EventList = () => {
  const [filters, setFilters] = useState({
    tags: [],
    dateRange: {
      start: '',
      end: ''
    },
    location: {
      name: '',
      radius: 50,
      coordinates: { lat: null, lng: null }
    }
  });

  const [events, setEvents] = useState([
    {
      id: 1,
      title: 'Summer Music Festival',
      description: 'Annual music festival featuring local and international artists',
      location: {
        name: 'Central Park',
        coordinates: { lat: 40.785091, lng: -73.968285 }
      },
      startDateTime: '2024-07-15T14:00',
      endDateTime: '2024-07-15T23:00',
      tags: ['music', 'outdoor', 'festival']
    },
    {
      id: 2,
      title: 'Tech Conference 2024',
      description: 'Technology and innovation conference',
      location: {
        name: 'Convention Center',
        coordinates: { lat: 40.755991, lng: -73.988991 }
      },
      startDateTime: '2024-08-20T09:00',
      endDateTime: '2024-08-21T18:00',
      tags: ['technology', 'business', 'conference']
    }
  ]);

  const handleTagFilter = (tag) => {
    setFilters(prev => ({
      ...prev,
      tags: prev.tags.includes(tag)
        ? prev.tags.filter(t => t !== tag)
        : [...prev.tags, tag]
    }));
  };

  const handleRadiusChange = (value) => {
    setFilters(prev => ({
      ...prev,
      location: { ...prev.location, radius: value }
    }));
  };

  const filteredEvents = events.filter(event => {
    // Tag filtering
    if (filters.tags.length > 0) {
      const hasMatchingTag = event.tags.some(tag => filters.tags.includes(tag));
      if (!hasMatchingTag) return false;
    }

    // Date filtering
    if (filters.dateRange.start && filters.dateRange.end) {
      const eventStart = new Date(event.startDateTime);
      const filterStart = new Date(filters.dateRange.start);
      const filterEnd = new Date(filters.dateRange.end);
      
      if (eventStart < filterStart || eventStart > filterEnd) return false;
    }

    return true;
  });

  return (
    <div className="max-w-6xl mx-auto p-6">
      <div className="flex gap-6">
        {/* Filters sidebar */}
        <div className="w-64 flex-shrink-0 space-y-6">
          <div className="bg-white p-4 rounded-lg shadow-md">
            <div className="flex items-center gap-2 mb-4">
              <Filter className="w-5 h-5" />
              <h3 className="font-medium">Filters</h3>
            </div>
            
            {/* Date Filter */}
            <div className="mb-4">
              <div className="flex items-center gap-2 mb-2">
                <Calendar className="w-4 h-4" />
                <span className="text-sm font-medium">Date Range</span>
              </div>
              <input
                type="date"
                className="w-full p-2 border rounded-md mb-2"
                value={filters.dateRange.start}
                onChange={(e) => setFilters(prev => ({
                  ...prev,
                  dateRange: { ...prev.dateRange, start: e.target.value }
                }))}
              />
              <input
                type="date"
                className="w-full p-2 border rounded-md"
                value={filters.dateRange.end}
                onChange={(e) => setFilters(prev => ({
                  ...prev,
                  dateRange: { ...prev.dateRange, end: e.target.value }
                }))}
              />
            </div>

            {/* Location Filter */}
            <div className="mb-4">
              <div className="flex items-center gap-2 mb-2">
                <MapPin className="w-4 h-4" />
                <span className="text-sm font-medium">Location</span>
              </div>
              <input
                type="text"
                placeholder="Enter location..."
                className="w-full p-2 border rounded-md mb-2"
                value={filters.location.name}
                onChange={(e) => setFilters(prev => ({
                  ...prev,
                  location: { ...prev.location, name: e.target.value }
                }))}
              />
              <div className="space-y-2">
                <label className="text-sm text-gray-600 block">
                  Radius: {filters.location.radius} km
                </label>
                <input
                  type="range"
                  min="0"
                  max="100"
                  step="10"
                  className="w-full"
                  value={filters.location.radius}
                  onChange={(e) => handleRadiusChange(Number(e.target.value))}
                />
              </div>
            </div>

            {/* Tag Filter */}
            <div>
              <div className="flex items-center gap-2 mb-2">
                <Tag className="w-4 h-4" />
                <span className="text-sm font-medium">Tags</span>
              </div>
              <div className="space-y-2">
                {['music', 'technology', 'sports', 'art', 'food'].map(tag => (
                  <label key={tag} className="flex items-center gap-2">
                    <input
                      type="checkbox"
                      checked={filters.tags.includes(tag)}
                      onChange={() => handleTagFilter(tag)}
                      className="rounded"
                    />
                    <span className="text-sm capitalize">{tag}</span>
                  </label>
                ))}
              </div>
            </div>
          </div>
        </div>

        {/* Events list */}
        <div className="flex-1 space-y-4">
          {filteredEvents.map(event => (
            <div key={event.id} className="bg-white p-4 rounded-lg shadow-md">
              <h3 className="text-xl font-semibold mb-2">{event.title}</h3>
              <p className="text-gray-600 mb-3">{event.description}</p>
              
              <div className="flex items-center gap-4 text-sm text-gray-500 mb-3">
                <div className="flex items-center gap-1">
                  <MapPin className="w-4 h-4" />
                  {event.location.name}
                </div>
                <div className="flex items-center gap-1">
                  <Calendar className="w-4 h-4" />
                  {new Date(event.startDateTime).toLocaleDateString()}
                </div>
              </div>
              
              <div className="flex gap-2">
                {event.tags.map(tag => (
                  <span
                    key={tag}
                    className="px-2 py-1 bg-blue-100 text-blue-800 rounded-full text-sm"
                  >
                    {tag}
                  </span>
                ))}
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};

export default EventList;