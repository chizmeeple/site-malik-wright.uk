{% if page.event_start_date and page.event_end_date %}
{% assign start_date = page.event_start_date | date: "%d %b %Y" %}
{% assign end_date = page.event_end_date | date: "%d %b %Y" %}
{% if start_date == end_date %}
**Date:** {{ start_date }}
{% else %}
**Date:**
{{ start_date }} – {{ end_date }}
{% endif %}
{% elsif page.event_start_date %}
{% assign start_date = page.event_start_date | date: "%d %b %Y" %}
**Date:** {{ start_date }}
{% elsif page.event_end_date %}
{% assign end_date = page.event_end_date | date: "%d %b %Y" %}
**Date:** {{ end_date }}
{% endif %}
