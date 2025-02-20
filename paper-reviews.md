---
layout: default
title: 논문 리뷰
permalink: /paper_reviews/
---
<style>
.page-container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 2rem;
}

.page-title {
  font-size: 2.5rem;
  color: #333;
  margin-bottom: 2rem;
  text-align: left;
  border-bottom: 2px solid #eaeaea;
  padding-bottom: 1rem;
}

.reviews-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 2rem;
  margin-top: 2rem;
}

.review-card {
  background-color: #fff;
  border-radius: 8px;
  box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
  padding: 1.5rem;
  transition: transform 0.3s ease, box-shadow 0.3s ease;
  cursor: pointer;
}

.review-card:hover {
  transform: translateY(-5px);
  box-shadow: 0 6px 12px rgba(0, 0, 0, 0.15);
}

.review-title {
  font-size: 1.4rem;
  margin-bottom: 0.5rem;
}

.review-title a {
  color: #2c3e50;
  text-decoration: none;
}

.review-date {
  font-size: 0.9rem;
  color: #7f8c8d;
  margin-bottom: 1rem;
}

.review-excerpt {
  font-size: 1rem;
  color: #34495e;
  margin-bottom: 1rem;
}
</style>

<div class="page-container">
  <h1 class="page-title">논문 리뷰</h1>
  <div class="reviews-grid">
    {% for review in site.paper_reviews %}
    <div class="review-card" data-url="{{ review.url | relative_url }}">
      <h2 class="review-title"><a href="{{ review.url | relative_url }}">{{ review.title }}</a></h2>
      <p class="review-date">작성일: {{ review.date | date: "%Y-%m-%d" }}</p>
      <p class="review-excerpt">{{ review.excerpt | strip_html | truncatewords: 30 }}</p>
    </div>
    {% endfor %}
  </div>
</div>

<script>
document.querySelectorAll('.review-card').forEach(function(card) {
  card.addEventListener('click', function(e) {
    if (!e.target.closest('a')) {
      window.location.href = this.getAttribute('data-url');
    }
  });
});
</script>