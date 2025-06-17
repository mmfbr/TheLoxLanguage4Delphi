#include "envstack.hpp"
#include "environment.hpp"
EnvStack::EnvStack()
{
}

std::optional<Environment> EnvStack::Get()
{
    if (not this->envs.empty() && this->current >= 0)
    {
        return std::make_optional<Environment>(this->envs.at(current--));
    }
    return std::nullopt;
}

Environment& EnvStack::GetRef()
{
    if (not this->envs.empty() && this->current >= 0)
    {
        return this->envs.at(current--);
    }
    throw new std::invalid_argument("No Environment Found.");
}

std::pair<Variable, Environment> EnvStack::Get(std::string identifier)
{
    std::optional<Environment> env_op = Get();
    if (env_op == std::nullopt)
    {
        throw std::invalid_argument("Variable Identifier '" + identifier + "' not found.");
    }
    Environment env = env_op.value();
    if (env.env_var.Get(identifier) == std::nullopt)
    {
        return Get(identifier);
    }
    Reset();
    return { env.env_var.Get(identifier).value(), env};
}

void EnvStack::Push(Environment env)
{
    this->envs.push_back(std::move(env));
    this->last_index++;
    Reset();
}

std::optional<Environment> EnvStack::Pop()
{
    if (this->envs.empty())
    {
        return std::nullopt;
    }
    Environment deleted_env = this->envs.at(last_index);
    this->last_index--;
    this->envs.pop_back();
    Reset();
    return std::make_optional<Environment>(deleted_env);
}

void EnvStack::Add(Variable var)
{
    try
    {
        Environment& env = GetRef();
        env.env_var.Set(var);
    }
    catch (std::invalid_argument e)
    {
        std::cout << e.what() << std::endl;
    }

     Reset();
}

void EnvStack::Assign(std::string identifier, std::any value)
{
    std::pair<Variable, Environment> var_op = std::move(Get(identifier));
    var_op.second.env_var.Assign(identifier, std::move(var_op.first));
}

void EnvStack::Reset()
{
    this->current = this->last_index;
}

