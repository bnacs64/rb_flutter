#!/bin/bash

# Grocery Store Supabase Deployment Script
# This script helps deploy the Supabase backend for the grocery store

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Supabase CLI is installed
check_supabase_cli() {
    if ! command -v supabase &> /dev/null; then
        print_error "Supabase CLI is not installed. Please install it first:"
        echo "npm install -g supabase"
        echo "or visit: https://supabase.com/docs/guides/cli"
        exit 1
    fi
    print_success "Supabase CLI is installed"
}

# Check if we're in the right directory
check_directory() {
    if [ ! -f "supabase/config.toml" ]; then
        print_error "supabase/config.toml not found. Please run this script from the project root."
        exit 1
    fi
    print_success "Found Supabase configuration"
}

# Function to start local development
start_local() {
    print_status "Starting local Supabase development environment..."
    
    # Check if Docker is running
    if ! docker info > /dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker first."
        exit 1
    fi
    
    supabase start
    
    print_success "Local Supabase is running!"
    echo ""
    echo "Access your local development environment:"
    echo "  Studio URL: http://localhost:54323"
    echo "  API URL: http://localhost:54321"
    echo "  DB URL: postgresql://postgres:postgres@localhost:54322/postgres"
    echo ""
}

# Function to reset local database
reset_local() {
    print_status "Resetting local database with migrations and seed data..."
    supabase db reset
    print_success "Database reset complete!"
}

# Function to deploy to production
deploy_production() {
    print_status "Deploying to production..."
    
    # Check if project is linked
    if [ ! -f ".supabase/config.toml" ]; then
        print_error "Project is not linked to Supabase. Please run:"
        echo "supabase link --project-ref YOUR_PROJECT_REF"
        exit 1
    fi
    
    # Confirm deployment
    echo ""
    print_warning "You are about to deploy to PRODUCTION!"
    read -p "Are you sure you want to continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Deployment cancelled."
        exit 0
    fi
    
    # Push database changes
    print_status "Pushing database migrations..."
    supabase db push
    
    print_success "Production deployment complete!"
}

# Function to generate TypeScript types
generate_types() {
    print_status "Generating TypeScript types..."
    
    # Create types directory if it doesn't exist
    mkdir -p types
    
    if [ "$1" = "local" ]; then
        supabase gen types typescript --local > types/supabase.ts
        print_success "Local TypeScript types generated in types/supabase.ts"
    else
        supabase gen types typescript > types/supabase.ts
        print_success "Production TypeScript types generated in types/supabase.ts"
    fi
}

# Function to seed database
seed_database() {
    if [ "$1" = "production" ]; then
        print_warning "Seeding production database..."
        read -p "Are you sure you want to seed the production database? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_status "Seeding cancelled."
            exit 0
        fi
        supabase db seed --remote
        print_success "Production database seeded!"
    else
        print_status "Seeding local database..."
        supabase db seed
        print_success "Local database seeded!"
    fi
}

# Function to show help
show_help() {
    echo "Grocery Store Supabase Deployment Script"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  local           Start local development environment"
    echo "  reset           Reset local database with migrations and seed data"
    echo "  deploy          Deploy to production"
    echo "  types [local]   Generate TypeScript types (add 'local' for local types)"
    echo "  seed [prod]     Seed database (add 'prod' for production)"
    echo "  status          Show Supabase status"
    echo "  stop            Stop local Supabase"
    echo "  help            Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 local        # Start local development"
    echo "  $0 reset        # Reset local database"
    echo "  $0 deploy       # Deploy to production"
    echo "  $0 types local  # Generate local types"
    echo "  $0 seed prod    # Seed production database"
    echo ""
}

# Main script logic
main() {
    check_supabase_cli
    check_directory
    
    case "${1:-help}" in
        "local")
            start_local
            ;;
        "reset")
            reset_local
            ;;
        "deploy")
            deploy_production
            ;;
        "types")
            generate_types "$2"
            ;;
        "seed")
            seed_database "$2"
            ;;
        "status")
            supabase status
            ;;
        "stop")
            print_status "Stopping local Supabase..."
            supabase stop
            print_success "Local Supabase stopped!"
            ;;
        "help"|*)
            show_help
            ;;
    esac
}

# Run main function with all arguments
main "$@"
