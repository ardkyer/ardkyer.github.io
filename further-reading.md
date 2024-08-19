---
layout: default
title: 추가 공부
permalink: /further_reading/
---

<style>
.further-readings-container {
    max-width: 1200px;
    margin: 0 auto;
    padding: 2rem;
}
.page-title {
    font-size: 2.5rem;
    color: #333;
    margin-bottom: 2rem;
    text-align: center;
}
.readings-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
    gap: 2rem;
}
.reading-card {
    background-color: #fff;
    border-radius: 8px;
    box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
    padding: 1.5rem;
    transition: transform 0.3s ease, box-shadow 0.3s ease;
    cursor: pointer;
}
.reading-card:hover {
    transform: translateY(-5px);
    box-shadow: 0 6px 12px rgba(0, 0, 0, 0.15);
}
.reading-title {
    font-size: 1.4rem;
    margin-bottom: 0.5rem;
}
.reading-title a {
    color: #2c3e50;
    text-decoration: none;
}
.reading-date {
    font-size: 0.9rem;
    color: #7f8c8d;
    margin-bottom: 1rem;
}
.reading-excerpt {
    font-size: 1rem;
    color: #34495e;
    margin-bottom: 1rem;
}
</style>

<div class="further-readings-container">
  <h1 class="page-title">추가 공부</h1>
  <div class="readings-grid">
    {% for reading in site.further_reading %}
      <div class="reading-card" data-url="{{ reading.url | relative_url }}">
        <h2 class="reading-title"><a href="{{ reading.url | relative_url }}">{{ reading.title }}</a></h2>
        <p class="reading-date">작성일: {{ reading.date | date: "%Y-%m-%d" }}</p>
        <p class="reading-excerpt">{{ reading.excerpt | strip_html | truncatewords: 30 }}</p>
      </div>
    {% endfor %}
  </div>
</div>

<script>
document.querySelectorAll('.reading-card').forEach(function(card) {
  card.addEventListener('click', function(e) {
    if (!e.target.closest('a')) {
      window.location.href = this.getAttribute('data-url');
    }
  });
});
</script>