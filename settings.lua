data:extend(
  {
    {
      type = "string-setting",
      name = "graftorio-train-histogram-buckets",
      setting_type = "startup",
      default_value = "10,30,60,90,120,180,240,300,600",
      allow_blank = false
    },
    {
      type = "bool-setting",
      name = "graftorio-server-save",
      setting_type = "runtime-global",
      default_value = 1
    },
    {
      type = "bool-setting",
      name = "graftorio-logistic-items",
      setting_type = "runtime-global",
      default_value = 0
    },
	{
		type = "int-setting",
		name = "graftorio-checking-rate",
		setting_type = "startup",
		default_value = "10"
	},
	{
		type = "bool-setting",
		name = "graftorio-train-tracking",
		setting_type="runtime-global",
		default_value=true
	}
  }
)
