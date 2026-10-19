weather_clock_module = weather_clock_module or {}
weather_clock_module.max_forecast_days = 7
weather_clock_module.max_description_num = 2
weather_clock_module.extend_type = {
  rainbow = 1,
  foggy = 2,
  meteor_shower = 3,
  major_meteor_shower = 4
}
weather_clock_module.clock_config_id = 80052
weather_clock_module.sunrise_hour = 6
weather_clock_module.sunset_hour = 18
weather_clock_module.sun_icon = {
  rise = {
    normal = "UISprite/Load/Weather/Icon_Weather_Sunrise",
    big = "UISprite/Load/Weather/Icon_Weather_Sunrise_B"
  },
  down = {
    normal = "UISprite/Load/Weather/Icon_Weather_Sunset",
    big = "UISprite/Load/Weather/Icon_Weather_Sunset_B"
  }
}
return weather_clock_module
