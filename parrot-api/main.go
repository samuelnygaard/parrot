package main

import (
	"fmt"
	"net/http"
	"os"
	"time"

	"github.com/Sirupsen/logrus"
	"github.com/anthonynsimon/parrot/parrot-api/api"
	"github.com/anthonynsimon/parrot/parrot-api/auth"
	"github.com/anthonynsimon/parrot/parrot-api/config"
	"github.com/anthonynsimon/parrot/parrot-api/datastore"
	"github.com/anthonynsimon/parrot/parrot-api/logger"
	"github.com/pressly/chi"
	"github.com/pressly/chi/middleware"
)

func init() {
	// Config log
	logrus.SetOutput(os.Stdout)
	logrus.SetFormatter(&logrus.TextFormatter{})
	logrus.SetLevel(logrus.InfoLevel)
}

// TODO: refactor this into cli to start server
func main() {
	conf, err := config.FromEnv()
	if err != nil {
		logrus.Fatal(err)
	}

	// init and ping datastore
	if conf.DBName == "" || conf.DBConn == "" {
		logrus.Fatal("Database not properly configured.")
	}

	ds, err := datastore.NewDatastore(conf.DBName, conf.DBConn)
	if err != nil {
		logrus.Fatal(err)
	}
	defer ds.Close()

	// Ping DB until service is up, block meanwhile
	blockAndRetry(5*time.Second, func() bool {
		if err = ds.Ping(); err != nil {
			logrus.Error(fmt.Sprintf("failed to ping datastore.\nerr: %s", err))
			return false
		}
		return true
	})

	migrate(conf, ds)

	router := chi.NewRouter()
	router.Use(
		func(next http.Handler) http.Handler {
			return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
				w.Header().Add("Strict-Transport-Security", "max-age=63072000; includeSubDomains")
				next.ServeHTTP(w, r)
			})
		},
		middleware.Recoverer,
		middleware.RequestID,
		middleware.RealIP,
		logger.Request,
		middleware.StripSlashes,
	)

	tp := auth.TokenProvider{Name: conf.AuthIssuer, SigningKey: []byte(conf.AuthSigningKey)}
	router.Mount("/api/v1/auth", auth.NewRouter(ds, tp))
	router.Mount("/api/v1", api.NewRouter(ds, tp))

	// config and init server
	bindInterface := ":" + conf.Port
	s := &http.Server{
		Addr:           bindInterface,
		Handler:        router,
		ReadTimeout:    10 * time.Second,
		WriteTimeout:   10 * time.Second,
		MaxHeaderBytes: 1 << 20,
	}

	logrus.Info(fmt.Sprintf("server listening on %s", bindInterface))

	logrus.Fatal(s.ListenAndServe())
}

func migrate(conf *config.AppConfig, ds datastore.Store) {
	logrus.Infof("migration strategy is set to '%s'", conf.MigrationStrategy)
	dirPath := fmt.Sprintf("./datastore/%s/migrations", conf.DBName)

	var fn func(string) error

	switch conf.MigrationStrategy {
	// Case when we want to start clean each time
	case "down,up":
		fn = func(path string) error {
			err := ds.MigrateDown(path)
			if err != nil {
				return err
			}
			err = ds.MigrateUp(path)
			if err != nil {
				return err
			}
			return nil
		}
	// Case when we want to apply migrations if needed
	case "up":
		fn = ds.MigrateUp
	// Case when we want to simply drop everything
	case "down":
		fn = ds.MigrateDown
	default:
		logrus.Fatalf("could not recognize migration strategy '%s'", conf.MigrationStrategy)
	}

	logrus.Info("migrating...")
	err := fn(dirPath)
	if err != nil {
		logrus.Fatal(err)
	}
	logrus.Info("migration completed successfully")
}

func blockAndRetry(d time.Duration, fn func() bool) {
	for !fn() {
		logrus.Infof("retrying in %s...\n", d.String())
		time.Sleep(d)
	}
}
