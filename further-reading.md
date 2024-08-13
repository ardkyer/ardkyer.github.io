---
layout: default
title: 추가 공부
---

<h2>추가 공부</h2>

<ul>
{% for reading in site.further_readings %}
  <li>
    <h3><a href="{{ reading.url | relative_url }}">{{ reading.title }}</a></h3>
    <p>작성일: {{ reading.date | date: "%Y-%m-%d" }}</p>
    {{ reading.excerpt }}
  </li>
{% endfor %}
</ul>