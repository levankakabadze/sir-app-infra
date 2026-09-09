# ==============================================================================
# MOVED BLOCKS
# Prevents Terraform from destroying and recreating resources when  
# refactoring from single resource to for_each keyed resources. 
# These blocks can be removed after all environments have been applied. 
# ==============================================================================

moved {
    from = aws_eip.nat
    to   = aws_eip.nat["a"]
}

moved {
    from = aws_nat_gateway.main
    to   = aws_nat_gateway.main["a"]
}

moved {
    from = aws_route_table.private
    to   = aws_route_table.private["a"]
}