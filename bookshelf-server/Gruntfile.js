// Generated on 2014-02-03 using generator-webapp 0.4.7
'use strict';

// ggf mit --verbose für fehlersuche aufrufen

module.exports = function (grunt) {

    // Load grunt tasks automatically
    require('load-grunt-tasks')(grunt);

    // Time how long tasks take. Can help when optimizing build times
    require('time-grunt')(grunt);

    // diese Variablen konnte ich NICHT benutzten???
    var options = {
        // Project settings
        paths: {
           // Configurable paths
           app: 'app',
           dist: 'dist'
        }
    };

    // Define the configuration for all the tasks
    grunt.initConfig({
        pkg: grunt.file.readJSON('package.json'),
        pkg_jquery: grunt.file.readJSON('bower_components/jquery/.bower.json'),
        bower_basepath: 'bower_components',

        // diese Variablen konnte ich benutzten
        paths: {
           // Configurable paths
            app: 'app',
            dist: 'dist',
            webjs: 'html/js',
            webcss: 'html/css',
            app_ma_icon_02: 'app/ma-icon-02',
            less_master_base: 'less',
            bower_font_awesome: '<%= bower_basepath %>/font-awesome',
            bower_jquery_dist: '<%= bower_basepath %>/jquery/dist',
            bower_jquery_lazy_load_dist: '<%= bower_basepath %>/jquery-lazyload',
            bower_jquery_1_dist: '<%= bower_basepath %>/jquery-legacy/dist'
        },

        clean  : {
            dist : {
                files : [{
                    dot : true,
                    src : ['.tmp', '<%= paths.dist %>/*', '!<%= paths.dist %>/.git*']
                }]
            }
        },
//
//        concat: {
//            dist: {
//                src: ['bower_components/jquery/dist/jquery.js'],
//                dest: '<%= paths.dist %>/js/jquery.js'
//            },
//            ma_js: {
//                //src: ['bower_components/jquery/dist/jquery.js'],
//                src: ['<%= paths.app %>/ma/js/ub-man.js',
//                      '<%= paths.app %>/ma/js/cookie_notice.js'
//                    ],
//                dest: '<%= paths.dist %>/js/ub-man.js',
//            },
//        },
//
        uglify: {
            dist: {
                options: {
                    mangle: false,
                    compress: true,
                    sourceMap: true,
                    preserveComments: false,
                    banner: "/*! jQuery v<%= pkg_jquery.version %> | " +
                            "(c) jQuery Foundation | jquery.org/license */"
                }
            },
            jquery_lazy_load: {
                options: {
                    mangle: false,
                    compress: true,
                    sourceMap: true,
                    preserveComments: false,
                    banner: "/*! jquery.lazyload.js | (c) UB Mannheim <%= grunt.template.today('yyyy.mm.dd HH:MM:ss') %> */"
                },
                files: {
                    '<%= paths.webjs %>/jquery-lazyload.min.js': '<%= paths.dist %>/js/jquery-lazyload.js'
                },
            },
            jquery_1: {
                options: {
                    mangle: false,
                    compress: true,
                    sourceMap: true,
                    preserveComments: false,
                    banner: "/*! jQuery v1.12.2 (<%= grunt.template.today('yyyy.mm.dd HH:MM:ss') %>) | " +
                            "(c) jQuery Foundation | jquery.org/license */"

                },
                files: {
                    '<%= paths.webjs %>/jquery-1.12.2.min.js': '<%= paths.bower_jquery_1_dist %>/jquery.js'
                },
            }
        },


        copy : {
            dist : {
                files : [ {
                    expand : true,
                    dot    : false,
                    cwd    : '<%= paths.app %>',
                    dest   : '<%= paths.dist %>',
                    src    : [ '*.{ico,png,txt}', '.htaccess', 'images/{,*/}*.webp', '{,*/}*.html','styles/fonts/{,*/}*.*' ]
                }]
            },
            styles : {
                expand : true,
                dot    : false,
                cwd    : '<%= paths.app %>/styles',
                dest   : '.tmp/styles/',
                src    : '{,*/}*.css'
            },
            ma_icon_02_dist : {
                files : {
                    '<%= paths.dist %>/css/ub_ma_icon.css' : '<%= paths.app_ma_icon_02 %>/styles.css'
                }
            },
            dist_jquery : {
                files : {
                    '<%= paths.webjs %>/jquery.js' : '<%= paths.bower_jquery_dist %>/jquery.js',
                    '<%= paths.webjs %>/jquery.min.js' : '<%= paths.bower_jquery_dist %>/jquery.min.js',
                    '<%= paths.webjs %>/jquery.min.map' : '<%= paths.bower_jquery_dist %>/jquery.min.map'
                }
            },
            dist_jquery_lazy_load : {
                files : {
                    '<%= paths.dist %>/js/jquery-lazyload.js' : '<%= paths.bower_jquery_lazy_load_dist %>/jquery.lazyload.js'
                }
            },
            ma_icon_02_resource : {
                files : {
                    '<%= paths.webcss %>/fonts/ma-icon-02.eot' : '<%= paths.app_ma_icon_02 %>/fonts/ma-icon-02.eot',
                    '<%= paths.webcss %>/fonts/ma-icon-02.svg' : '<%= paths.app_ma_icon_02 %>/fonts/ma-icon-02.svg',
                    '<%= paths.webcss %>/fonts/ma-icon-02.ttf' : '<%= paths.app_ma_icon_02 %>/fonts/ma-icon-02.ttf',
                    '<%= paths.webcss %>/fonts/ma-icon-02.woff' : '<%= paths.app_ma_icon_02 %>/fonts/ma-icon-02.woff'
                }
            },
            ma_icon_02_dist_min_to_resource : {
                files : {
                    '<%= paths.webcss %>/ub_ma_icon.min.css' : '<%= paths.dist %>/css/ub_ma_icon.min.css',
                    '<%= paths.webcss %>/ub_ma_icon.min.css.map' : '<%= paths.dist %>/css/ub_ma_icon.min.css.map'
                }
            },
            font_awesome_bootstrap_in_css: {
                files : {
                    '<%= paths.webcss %>/Font-Awesome/css/font-awesome.min.css' : '<%= paths.bower_font_awesome %>/css/font-awesome.min.css',
                    '<%= paths.webcss %>/Font-Awesome/css/font-awesome.css.map' : '<%= paths.bower_font_awesome %>/css/font-awesome.css.map',
                    '<%= paths.webcss %>/Font-Awesome/css/font-awesome.css' : '<%= paths.bower_font_awesome %>/css/font-awesome.css',
                    '<%= paths.webcss %>/Font-Awesome/fonts/fontawesome-webfont.woff2' : '<%= paths.bower_font_awesome %>/fonts/fontawesome-webfont.woff2',
                    '<%= paths.webcss %>/Font-Awesome/fonts/fontawesome-webfont.woff' : '<%= paths.bower_font_awesome %>/fonts/fontawesome-webfont.woff',
                    '<%= paths.webcss %>/Font-Awesome/fonts/fontawesome-webfont.ttf' : '<%= paths.bower_font_awesome %>/fonts/fontawesome-webfont.ttf',
                    '<%= paths.webcss %>/Font-Awesome/fonts/fontawesome-webfont.svg' : '<%= paths.bower_font_awesome %>/fonts/fontawesome-webfont.svg',
                    '<%= paths.webcss %>/Font-Awesome/fonts/fontawesome-webfont.eot' : '<%= paths.bower_font_awesome %>/fonts/fontawesome-webfont.eot',
                    '<%= paths.webcss %>/Font-Awesome/fonts/FontAwesome.otf' : '<%= paths.bower_font_awesome %>/fonts/FontAwesome.otf'
                }
            }
        },

        cssmin: {
          options: {
            compatibility: 'ie8',
            keepSpecialComments: '*',
            noAdvanced: true,
            sourceMap: true
          },
          css_core: {
            sourceMap: true,
            files: {
                '<%= paths.webcss %>/booklist_erz.min.css': '<%= paths.dist %>/css/booklist.css'
            }
          },
          css_substitute: {
            sourceMap: true,
            files: {
                '<%= paths.webcss %>/substitute.min.css': '<%= paths.dist %>/css/substitute.css'
            }
          },
          css_gesten: {
            sourceMap: true,
            files: {
                '<%= paths.webcss %>/gesten.min.css': '<%= paths.dist %>/css/gesten.css'
            }
          },
          css_externeurls: {
            sourceMap: true,
            files: {
                '<%= paths.webcss %>/externeurls.min.css': '<%= paths.dist %>/css/externeurls.css'
            }
          },
          mafont: {
            sourceMap: true,
            files: {
                '<%= paths.dist %>/css/ub_ma_icon.min.css': '<%= paths.dist %>/css/ub_ma_icon.css'
            }
          }
        },

        less: {
          maCompileBase : {
            options: {
              strictMath: true,
              sourceMap: true,
              outputSourceFiles: true,
              paths: '<%= paths.app %>/less'
            },
            // gilt nicht hier! Vor dem kompilieren wurde die Version aus relaunch_2016 hierher kopiert
            files: {
                '<%= paths.dist %>/css/booklist.css': '<%= paths.app %>/less/booklist.less',
                '<%= paths.dist %>/css/substitute.css': '<%= paths.app %>/less/substitute.less',
                '<%= paths.dist %>/css/gesten.css': '<%= paths.app %>/less/gesten.less',
                '<%= paths.dist %>/css/externeurls.css': '<%= paths.app %>/less/externeurls.less'
            }
          }
        },

        autoprefixer: {
          options: {
            browsers: [
              'Android 2.3',
              'Android >= 4',
              'Chrome >= 20',
              'Firefox >= 24', // Firefox 24 is the latest ESR
              'Explorer >= 8',
              'iOS >= 6',
              'Opera >= 12',
              'Safari >= 6'
            ]
          },
          css_core: {
            options: {
              map: true
            },
            src: '<%= paths.dist %>/css/booklist.css'
          }
        }

    });

    // werden ersetzt durch require('load-grunt-tasks')(grunt); siehe oben
    //grunt.loadNpmTasks('grunt-bower-task');
    //grunt.loadNpmTasks('grunt-bower-concat');

    grunt.registerTask('build', [
        'clean:dist',
        'concat:dist',
        'uglify:dist',
        'copy:dist'
    ]);

    // Default
    grunt.registerTask('default', ['bsdist-css']);

    grunt.registerTask('bsdist-css', [
        'clean:dist',
        'copy:font_awesome_bootstrap_in_css',
        'less:maCompileBase',
        'autoprefixer:css_core',
        'cssmin:css_core',
        'cssmin:css_substitute',
        'cssmin:css_gesten',
        'cssmin:css_externeurls',
        'copy:dist_jquery',
        'copy:dist_jquery_lazy_load',
        'uglify:jquery_lazy_load',
        'uglify:jquery_1'
    ]);

    grunt.registerTask('ma-font', [
        'copy:ma_icon_02_dist',
        'copy:ma_icon_02_resource',
        'cssmin:mafont',
        'copy:ma_icon_02_dist_min_to_resource'
    ]);

};
