---
layout: default
title: 논문 리뷰
---

<h2>논문 리뷰</h2>

<ul>
{% for review in site.paper_reviews %}
  <li>
    <h3><a href="{{ review.url | relative_url }}">{{ review.title }}</a></h3>
    <p>작성일: {{ review.date | date: "%Y-%m-%d" }}</p>
    {{ review.excerpt }}
  </li>
{% endfor %}
</ul>