// Package travels is David G.'s map of the cities visited. The page, the map
// and the checks all come from travellog; this realm only stores the cities
// and decides who may change them.
package travels

import "gno.land/p/g1rayfgklwl0aspz488wvrcrvt7t2quy6q06lgk2/travellog/v0"

// admin is the only address allowed to add or remove cities.
const admin = address("g1rayfgklwl0aspz488wvrcrvt7t2quy6q06lgk2")

const page = "/r/g1rayfgklwl0aspz488wvrcrvt7t2quy6q06lgk2/travels"

var log travellog.Log

// AddMany adds cities in one transaction. Only the admin can call it.
//
// data lists the cities split by ";", each as "lat,lon,year,CC,name":
// latitude and longitude in hundredths of a degree, the year of the visit, 0
// when unknown, the two-letter country code and the name, which holds no
// comma. web/travels.html builds it.
//
// Example:
//
//	4886,235,2024,FR,Paris;5237,490,2019,NL,Amsterdam
func AddMany(cur realm, data string) {
	assertAdmin(cur)
	log.AddMany(data)
}

// RemoveMany removes cities in one transaction. Only the admin can call it.
//
// data lists the cities split by ";", each as "CC,name", such as
// "FR,Paris;NL,Amsterdam".
func RemoveMany(cur realm, data string) {
	assertAdmin(cur)
	log.RemoveMany(data)
}

// Cities returns every city on the map, one "lat,lon,year,CC,name" line each.
func Cities() string { return log.Cities() }

// Render serves the whole world at "", a continent such as "europe", and a
// year such as "2024".
func Render(path string) string { return log.Render(path, page) }

func assertAdmin(cur realm) {
	if cur.Previous().Address() != admin {
		panic("unauthorized")
	}
}
