class_name NameUtils

static func format_stat_name(stat: String) -> String: # Turns reload_speed into Reload Speed
	return " ".join(Array(stat.split("_")).map(func(w): return w.capitalize()))