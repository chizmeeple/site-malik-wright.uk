require 'icalendar'
require 'date'

module Jekyll
  class ConventionsICSGenerator < Generator
    safe true
    priority :low

    def generate(site)
      # Store the site reference and generate calendar content
      @site = site
      @calendar = build_calendar(site)
    end

    def build_calendar(site)
      calendar = Icalendar::Calendar.new
      calendar.prodid = "-//#{site.config['title'] || 'Jekyll'}//Conventions Calendar//EN"
      calendar.version = "2.0"
      
      # Get all convention posts
      convention_posts = site.posts.docs.select do |post|
        post.data['categories']&.include?('conventions') &&
        post.data['event_start_date'] &&
        post.data['event_end_date']
      end
      
      # Sort by event_start_date
      convention_posts.sort_by! { |post| post.data['event_start_date'] }
      
      convention_posts.each do |post|
        event = Icalendar::Event.new
        
        # Parse dates - they're in YYYY-MM-DD format
        start_date = Date.parse(post.data['event_start_date'].to_s)
        end_date = Date.parse(post.data['event_end_date'].to_s)
        
        # For all-day events, use DATE format (no time component)
        # End date should be exclusive (day after last day) for all-day events
        event.dtstart = Icalendar::Values::Date.new(start_date)
        event.dtend = Icalendar::Values::Date.new(end_date + 1)
        
        event.summary = post.data['title'] || post.data['name'] || 'Convention'
        event.description = post.data['description'] || post.content.strip
        
        # Add URL if available
        if post.data['event_link']
          event.url = post.data['event_link']
        else
          # Use the post URL
          base_url = site.config['url'] || ''
          baseurl = site.config['baseurl'] || ''
          event.url = "#{base_url}#{baseurl}#{post.url}"
        end
        
        # Add location if available
        if post.data['event_venue']
          event.location = post.data['event_venue']
        end
        
        # Add UID for uniqueness
        # Use post ID or generate from URL
        post_id = post.id || post.url.gsub(/[^a-z0-9]/i, '-')
        event.uid = "#{post.data['event_start_date']}-#{post_id}@#{site.config['url'] || 'localhost'}"
        
        # Set created and last-modified timestamps
        event.created = post.date
        event.last_modified = post.date
        
        calendar.add_event(event)
      end
      
      calendar
    end
  end

  # Hook to write the file after Jekyll has finished writing the site
  Jekyll::Hooks.register :site, :post_write do |site|
    # Find the generator instance to get the calendar
    generator = site.generators.find { |g| g.is_a?(ConventionsICSGenerator) }
    next unless generator
    
    calendar = generator.instance_variable_get(:@calendar)
    next unless calendar
    
    # Write to destination directory after Jekyll has finished
    dest_dir = site.dest
    calendar_dir = File.join(dest_dir, 'calendar')
    FileUtils.mkdir_p(calendar_dir)
    
    # Write the ICS file to destination directory
    ics_file = File.join(calendar_dir, 'conventions.ics')
    File.write(ics_file, calendar.to_ical)
  end
end
