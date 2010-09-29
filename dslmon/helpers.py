#!/usr/bin/env python

from string import join
import time

one_minute = 60
one_hour = one_minute * 60
one_day = one_hour * 24
one_month = one_day * 30
one_year = one_day * 365

def pluralise(val, unit):
    resp = str(val) + " " + unit
    if val > 1: resp += 's'
    return resp

def count_up(amount, delta):
    return (int(amount / delta), amount % delta)

def time_since(then):
    global one_minute, one_hour, one_day, one_month, one_year

    now = int(time.time())

    (years, rem) = count_up(now - then, one_year)
    (months, rem) = count_up(rem, one_month)
    (days, rem) = count_up(rem, one_day)
    (hours, rem) = count_up(rem, one_hour)
    (minutes, rem) = count_up(rem, one_minute)

    resp = []
    if years > 0:
        resp += [pluralise(years, 'year')]
    if months > 0:
        resp += [pluralise(months, 'month')]

    if len(resp) > 1:
        return join(resp, ', ') + " ago"

    if days > 0:
        resp += [pluralise(days, 'day')]
    if hours > 0:
        resp += [pluralise(hours, 'hour')]
    if minutes > 0:
        resp += [pluralise(minutes, 'minute')]

    if len(resp) == 0:
        return "now"
    else:
        return join(resp, ', ') + " ago"
