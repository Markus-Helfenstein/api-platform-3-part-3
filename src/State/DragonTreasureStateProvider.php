<?php

namespace App\State;

use ApiPlatform\Doctrine\Orm\State\CollectionProvider;
use ApiPlatform\Doctrine\Orm\State\ItemProvider;
use ApiPlatform\Metadata\CollectionOperationInterface;
use ApiPlatform\Metadata\Operation;
use ApiPlatform\State\ProviderInterface;
use App\Entity\DragonTreasure;
use Symfony\Bundle\SecurityBundle\Security;
use Symfony\Component\DependencyInjection\Attribute\Autowire;

class DragonTreasureStateProvider implements ProviderInterface
{
    public function __construct(
        #[Autowire(service: ItemProvider::class)]
        private readonly ProviderInterface $decoratedItemProvider,
        #[Autowire(service: CollectionProvider::class)]
        private readonly ProviderInterface $decoratedCollectionProvider,
        private readonly Security $security,
    )
    {
    }

    public function provide(Operation $operation, array $uriVariables = [], array $context = []): object|array|null
    {
        // Collection
        if ($operation instanceof CollectionOperationInterface) {
            /** @var iterable<DragonTreasure> $paginator */
            $paginator = $this->decoratedCollectionProvider->provide($operation, $uriVariables, $context);

            foreach ($paginator as $item) {
                $item->setIsOwnedByAuthenticatedUser(
                    $this->security->getUser() === $item->getOwner()
                );
            }

            return $paginator;
        }

        // Item
        $treasure = $this->decoratedItemProvider->provide($operation, $uriVariables, $context);

        if (!$treasure instanceof DragonTreasure) {
            return null;
        }

        $treasure->setIsOwnedByAuthenticatedUser(
            $this->security->getUser() === $treasure->getOwner()
        );

        return $treasure;
    }
}
