use std::env;
use std::fs;
use std::fs::File;
use std::io::BufRead;
use std::io::BufReader;
use std::path::Path;
use std::process;

fn main() {
    static ENV_VAR: &str = "PLATFORM";
    static FILE_NAME: &str = "platform";
    static APP_HEAP_SIZE: &str = "APP_HEAP_SIZE";


    println!("cargo:rerun-if-env-changed={}", ENV_VAR);
    println!("cargo:rerun-if-env-changed={}", APP_HEAP_SIZE);
    println!("cargo:rerun-if-changed={}", FILE_NAME);

    let platform_name =
        read_env_var(ENV_VAR).or_else(|| read_board_name_from_file(FILE_NAME));
    if let Some(platform_name) = platform_name {
        println!("cargo:rustc-env={}={}", ENV_VAR, platform_name);
        copy_linker_file(&platform_name.trim());
    } else {
        println!(
            "cargo:warning=No platform specified. \
             Remember to manually specify a linker file.",
        );
    }

    if let Some(s) = read_env_var(APP_HEAP_SIZE) {
        println!("cargo:rustc-env=APP_HEAP_SIZE={}",s);
    } else {
        // Just use a default of 1024 if nothing is passed in
        // Set both the rustc env and the regular environment for running
        // elf2tab afterwards
        env::set_var("APP_HEAP_SIZE", "1024");
        println!("cargo:rustc-env=APP_HEAP_SIZE=1024");
    }
}

fn read_env_var(env_var: &str) -> Option<String> {
    env::var_os(env_var).map(|os_string| os_string.into_string().unwrap())
}

fn read_board_name_from_file(file_name: &str) -> Option<String> {
    let path = Path::new(file_name);
    if !path.exists() {
        return None;
    }

    let board_file = File::open(path).unwrap();
    let mut board_name = String::new();
    BufReader::new(board_file)
        .read_line(&mut board_name)
        .unwrap();
    Some(board_name)
}

fn copy_linker_file(platform_name: &str) {
    let linker_file_name = format!("layout_{}.ld", platform_name);
    let path = Path::new(&linker_file_name);
    if !path.exists() {
        println!("Cannot find layout file {:?}", path);
        process::exit(1);
    }
    fs::copy(linker_file_name, "layout.ld").unwrap();
}
