package travels

import (
	"strings"
	"testing"

	"gno.land/p/nt/testutils/v0"
	"gno.land/p/nt/uassert/v0"
)

var mallory = testutils.TestAddress("mallory")

func TestAdminAddsAndRemoves(cur realm, t *testing.T) {
	testing.SetRealm(testing.NewUserRealm(admin))
	AddMany(cross(cur), "4886,235,2024,FR,Paris;5237,490,2019,NL,Amsterdam")
	RemoveMany(cross(cur), "NL,Amsterdam")
	uassert.Equal(t, "4886,235,2024,FR,Paris", Cities())
	uassert.True(t, strings.Contains(Render(""), "[Europe]("+page+":europe)"))
	RemoveMany(cross(cur), "FR,Paris")
}

func TestOnlyAdmin(cur realm, t *testing.T) {
	testing.SetRealm(testing.NewUserRealm(mallory))
	uassert.AbortsContains(t, cur, "unauthorized", func() { AddMany(cross(cur), "4886,235,2024,FR,Paris") })
	uassert.AbortsContains(t, cur, "unauthorized", func() { RemoveMany(cross(cur), "FR,Paris") })
	// A realm calling on the admin's behalf is refused too: the check reads
	// the realm that called, never the account that signed.
	testing.SetOriginCaller(admin)
	testing.SetRealm(testing.NewCodeRealm("gno.land/r/evil/proxy"))
	uassert.AbortsContains(t, cur, "unauthorized", func() { AddMany(cross(cur), "4886,235,2024,FR,Paris") })
	uassert.Equal(t, "", Cities())
}
