---
layout: default
title: 캘린더
---

<div id="calendar"></div>

<script>
document.addEventListener('DOMContentLoaded', function() {
  var calendarEl = document.getElementById('calendar');
  window.calendar = new FullCalendar.Calendar(calendarEl, {
    initialView: 'dayGridMonth',
    headerToolbar: {
      left: '',
      center: 'title',
      right: 'prev,next today' 
    },
    events: [
      {% for post in site.posts %}
      {
        title: '{{ post.title | escape }}',
        start: '{{ post.date | date: "%Y-%m-%d" }}',
        url: '{{ post.url | relative_url }}',
        className: 'post-event',
        extendedProps: {
          post_id: '{{ post.id }}',
          category: 'post'
        }
      },
      {% endfor %}
      {% for review in site.paper_reviews %}
      {
        title: '{{ review.title | escape }}',
        start: '{{ review.date | date: "%Y-%m-%d" }}',
        url: '{{ review.url | relative_url }}',
        className: 'paper-review-event',
        extendedProps: {
          post_id: '{{ review.id }}',
          category: 'paper_review'
        }
      },
      {% endfor %}
      {% for reading in site.further_readings %}
      {
        title: '{{ reading.title | escape }}',
        start: '{{ reading.date | date: "%Y-%m-%d" }}',
        url: '{{ reading.url | relative_url }}',
        className: 'further-reading-event',
        extendedProps: {
          post_id: '{{ reading.id }}',
          category: 'further_reading'
        }
      },
      {% endfor %}
      {% for log in site.dev_logs %}
      {
        title: '{{ log.title | escape }}',
        start: '{{ log.date | date: "%Y-%m-%d" }}',
        url: '{{ log.url | relative_url }}',
        className: 'dev-log-event',
        extendedProps: {
          post_id: '{{ log.id }}',
          category: 'dev_log'
        }
      },
      {% endfor %}
    ],
    eventClick: function(info) {
      info.jsEvent.preventDefault();
      if (info.event.url) {
        window.location.href = info.event.url;
      }
    },
    eventContent: function(arg) {
      return {
        html: '<div class="fc-event-title" style="white-space: normal; overflow: hidden; text-overflow: ellipsis;">' + arg.event.title + '</div>'
      };
    },
    dayCellContent: function(arg) {
      return {
        html: '<div class="fc-daygrid-day-number">' + arg.dayNumberText + '</div>'
      };
    },
    eventDidMount: function(info) {
      info.el.setAttribute('title', info.event.title);
    }
  });
  window.calendar.render();
});
</script>