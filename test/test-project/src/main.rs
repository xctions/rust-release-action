use clap::{Arg, Command};
use serde::{Deserialize, Serialize};
use std::io::{self, Write};

#[derive(Serialize, Deserialize, Debug)]
struct Config {
    name: String,
    version: String,
    features: Vec<String>,
}

impl Default for Config {
    fn default() -> Self {
        Config {
            name: "test-rust-app".to_string(),
            version: env!("CARGO_PKG_VERSION").to_string(),
            features: vec!["basic".to_string()],
        }
    }
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let matches = Command::new("test-rust-app")
        .version(env!("CARGO_PKG_VERSION"))
        .author("Test User <test@example.com>")
        .about("A simple test Rust application for testing GitHub Actions workflow")
        .arg(
            Arg::new("config")
                .short('c')
                .long("config")
                .value_name("FILE")
                .help("Sets a custom config file")
        )
        .arg(
            Arg::new("output")
                .short('o')
                .long("output")
                .value_name("FORMAT")
                .help("Output format: text, json")
                .default_value("text")
        )
        .arg(
            Arg::new("verbose")
                .short('v')
                .long("verbose")
                .action(clap::ArgAction::Count)
                .help("Increase verbosity level")
        )
        .arg(
            Arg::new("platform")
                .long("platform")
                .help("Show platform information")
                .action(clap::ArgAction::SetTrue)
        )
        .get_matches();

    let config = if let Some(config_path) = matches.get_one::<String>("config") {
        match std::fs::read_to_string(config_path) {
            Ok(content) => serde_json::from_str(&content)?,
            Err(_) => {
                eprintln!("Warning: Could not read config file '{}', using defaults", config_path);
                Config::default()
            }
        }
    } else {
        Config::default()
    };

    let output_format = matches.get_one::<String>("output").unwrap();
    let verbose_level = matches.get_count("verbose");
    let show_platform = matches.get_flag("platform");

    if verbose_level > 0 {
        eprintln!("Verbose level: {}", verbose_level);
        if verbose_level > 1 {
            eprintln!("Config: {:?}", config);
        }
    }

    match output_format.as_str() {
        "json" => {
            let mut output = serde_json::json!({
                "name": config.name,
                "version": config.version,
                "features": config.features,
                "status": "success"
            });

            if show_platform {
                output["platform"] = serde_json::json!({
                    "os": std::env::consts::OS,
                    "arch": std::env::consts::ARCH,
                    "family": std::env::consts::FAMILY,
                });
            }

            println!("{}", serde_json::to_string_pretty(&output)?);
        }
        "text" => {
            println!("🚀 {} v{}", config.name, config.version);
            println!("Features: {}", config.features.join(", "));
            
            if show_platform {
                println!("Platform: {} {} ({})", 
                    std::env::consts::OS, 
                    std::env::consts::ARCH,
                    std::env::consts::FAMILY
                );
            }
            
            println!("Status: ✅ Success");
        }
        _ => {
            eprintln!("Error: Unknown output format '{}'", output_format);
            std::process::exit(1);
        }
    }

    // Test some basic functionality
    test_basic_operations(verbose_level)?;

    Ok(())
}

fn test_basic_operations(verbose_level: u8) -> Result<(), Box<dyn std::error::Error>> {
    if verbose_level > 0 {
        eprintln!("Running basic operations test...");
    }

    // Test file I/O
    let test_data = Config {
        name: "test".to_string(),
        version: "1.0.0".to_string(),
        features: vec!["test".to_string(), "io".to_string()],
    };

    let serialized = serde_json::to_string(&test_data)?;
    let _deserialized: Config = serde_json::from_str(&serialized)?;

    if verbose_level > 1 {
        eprintln!("✅ Serialization test passed");
    }

    // Test error handling
    let result = std::fs::read_to_string("/nonexistent/file");
    if result.is_err() && verbose_level > 1 {
        eprintln!("✅ Error handling test passed");
    }

    // Test environment variables
    let home = std::env::var("HOME").or_else(|_| std::env::var("USERPROFILE"));
    if verbose_level > 1 {
        match home {
            Ok(_) => eprintln!("✅ Environment variable test passed"),
            Err(_) => eprintln!("⚠️ Environment variable test skipped"),
        }
    }

    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_config_default() {
        let config = Config::default();
        assert_eq!(config.name, "test-rust-app");
        assert!(!config.version.is_empty());
        assert!(!config.features.is_empty());
    }

    #[test]
    fn test_config_serialization() {
        let config = Config::default();
        let serialized = serde_json::to_string(&config).unwrap();
        let deserialized: Config = serde_json::from_str(&serialized).unwrap();
        assert_eq!(config.name, deserialized.name);
        assert_eq!(config.version, deserialized.version);
        assert_eq!(config.features, deserialized.features);
    }

    #[test]
    fn test_basic_operations() {
        // This should not panic
        test_basic_operations(0).unwrap();
    }
}