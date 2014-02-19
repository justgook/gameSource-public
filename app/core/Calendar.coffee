class CalendarView extends Backbone.View
  tagName:"article"
  attributes:
    "data-module":"calendar"
  i18n:
    months: ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"],
    month_short: ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    weekday: ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    weekday_short: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

  config:
    firstWeekDay: 1
    firstMonth: 0
    monthCount: 12
    defaultView: "year" # year | month | week | day
    views: ["year", "month", "week", "day"]

  templates:
    year: require "./year"
    month: require "./month"
    week: require "./week"
    day: require "./day"

  events:
    "click .nextDay": "nextDay"

  constructor: (options)->
    @date = new Date
    super
  getMonday = (date) ->
    newDate = new Date date
    day = newDate.getDay() or 7
    newDate.setHours -24 * (day - 1) if day isnt 1
    newDate

  getWeek: (date = @date)->
    onejan = new Date(date.getFullYear(), 0, 1)

    result = Math.ceil (((date - onejan) / 86400000) + onejan.getDay() + 1) / 7
    #TODO fix it to generate based on first day
    #hardcoded for monday
    if date.getDay()
      result
    else
      result - 1

  setContent: (content)->
    @$el.html content

  _generateMonth: (year, monthNr)->
    firstDayOfMonth = new Date year, monthNr, 1
    lastDayOfMonth = new Date year, monthNr + 1, 0

    output = n: monthNr, t: lastDayOfMonth.getDate(), m: @i18n.months[monthNr], M: @i18n.month_short[monthNr], weeks: []
    #TODO FIXME NOT ONLY FOR MONDAY AS FIRST DAY!

    weekDayStart = firstDayOfMonth.getDay() or 7
    monthDayCounter = 1
    for weekNr in [(@getWeek firstDayOfMonth)..(@getWeek lastDayOfMonth)]
      weekLength = output.weeks.push W: weekNr, days: []
      for dayOfWeekIndex in [weekDayStart..@config.firstWeekDay + 6]
        dayOfWeek = dayOfWeekIndex % 7
        output.weeks[weekLength - 1].days[dayOfWeekIndex - @config.firstWeekDay] = w: dayOfWeek, d: monthDayCounter, name: @i18n.weekday[dayOfWeek], short: @i18n.weekday_short[dayOfWeek]
        break if ++monthDayCounter > lastDayOfMonth.getDate()
      weekDayStart = @config.firstWeekDay
    output

  _generateWeek: (date = @date, options)->
    date = new Date 2014, 0, 27
    options ?= {}
    options.oneMonth ?= true
    options.appendWeekNr ?= false
    output = []
    output.W = @getWeek date if options.appendWeekNr

    weekDate = getMonday(date)
    start = 0
    end = 6
    if options.oneMonth
      console.log date.getDay()
      sunday = new Date weekDate.getTime() + 86400000 * 6  #.getTime() #< weekDate.getTime() + 86400000 * 7

      mondayMonth = weekDate.getMonth()
      dateMonth = date.getMonth()
      sundayMonth = sunday.getMonth()

      if mondayMonth isnt dateMonth and (mondayMonth < dateMonth or (mondayMonth is 11 and dateMonth is 0))
        weekDate = new Date date.getFullYear(), date.getMonth(), 1
        start = (weekDate.getDay() or 7) - 1
      else if sundayMonth isnt dateMonth and (sundayMonth > dateMonth or (sundayMonth is 0 and dateMonth is 11))
        end = (new Date(date.getFullYear(), date.getMonth() + 1, 0)).getDay() - 1

    for weekDay in [start..end]
      output[weekDay] = weekDate.getDate()
      weekDate.setTime weekDate.getTime() + 86400000
    output

  generate: (what = @config.defaultView, date = @date)->
    switch what
      when "year" #cache current year
        years = [Y: date.getFullYear()]
        yearIndex = 0
        years[yearIndex].months = []
        for i in [0..@config.monthCount - 1]
          monthNr = i + @config.firstMonth
          yearIndex = (monthNr / 12) | 0
          years[yearIndex] ?= Y: years[yearIndex-1].Y + 1, months:[]
          monthNr = monthNr - 12 if monthNr > 11
          monthLength = years[yearIndex].months.push @_generateMonth(years[yearIndex].Y, monthNr)
        years
      when "month"
        monthNr = date.getMonth()
        year = date.getFullYear()
        @_generateMonth(year, monthNr)
      when "week"
        @_generateWeek date
      when "day"
        []

  renderYear: (date = @date)->
    @setContent @templates.year data: @generate "year", date

  renderMonth: (date = @date)->
    @setContent @templates.year @generate "month", date

  renderWeek: (date = @date)->
    @setContent @templates.year @generate "week", date

  renderDay: (date = @date)->
    @setContent @templates.year @generate "day", date

  render: (date = @date)->
    @setContent @templates[@defaultView] @generate @defaultView, date

module.exports = CalendarView



