import React from 'react';
import { render, fireEvent, waitFor } from '@testing-library/react';
import { TagManagement } from '../components/TagManagement';
import { TagContext } from '../context/TagContext';
import { NotificationContext } from '../components/NotificationSystem';

const mockTags = [
  { id: 1, name: 'music', color: '#3B82F6', eventCount: 5 },
  { id: 2, name: 'sports', color: '#10B981', eventCount: 3 }
];

const mockCreateTag = jest.fn();
const mockUpdateTag = jest.fn();
const mockDeleteTag = jest.fn();
const mockFetchTags = jest.fn();
const mockAddNotification = jest.fn();

const renderTagManagement = () => {
  return render(
    <NotificationContext.Provider value={{ addNotification: mockAddNotification }}>
      <TagContext.Provider value={{
        tags: mockTags,
        loading: false,
        error: null,
        createTag: mockCreateTag,
        updateTag: mockUpdateTag,
        deleteTag: mockDeleteTag,
        fetchTags: mockFetchTags
      }}>
        <TagManagement />
      </TagContext.Provider>
    </NotificationContext.Provider>
  );
};

describe('TagManagement', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('renders tag list correctly', () => {
    const { getByText } = renderTagManagement();
    expect(getByText('music')).toBeInTheDocument();
    expect(getByText('sports')).toBeInTheDocument();
  });

  it('creates a new tag', async () => {
    const { getByPlaceholderText, getByText } = renderTagManagement();
    fireEvent.change(getByPlaceholderText('Tag name'), {
      target: { value: 'art' }
    });
    fireEvent.click(getByText('Add Tag'));
    await waitFor(() => {
      expect(mockCreateTag).toHaveBeenCalledWith(expect.objectContaining({
        name: 'art'
      }));
    });
  });
})